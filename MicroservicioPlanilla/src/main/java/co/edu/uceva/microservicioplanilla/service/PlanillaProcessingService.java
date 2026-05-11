package co.edu.uceva.microservicioplanilla.service;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class PlanillaProcessingService {

    private final S3StorageService s3StorageService;
    private final CompositeAiService compositeAiService;
    private final ObjectMapper objectMapper;
    private final ITipoCampoRepository tipoCampoRepository;
    private final IPlanillaRepository planillaRepository;

    @Value("${s3.presign-ttl-seconds:3600}")
    private String presignTtlSecondsRaw;

    @Value("${s3.upload-sources:false}")
    private boolean uploadSourceImages;

    public PlanillaProcessingService(
        S3StorageService s3StorageService,
        CompositeAiService compositeAiService,
        ObjectMapper objectMapper,
        ITipoCampoRepository tipoCampoRepository,
        IPlanillaRepository planillaRepository
    ) {
        this.s3StorageService = s3StorageService;
        this.compositeAiService = compositeAiService;
        this.objectMapper = objectMapper;
        this.tipoCampoRepository = tipoCampoRepository;
        this.planillaRepository = planillaRepository;
    }

    public List<PlanillaDigitalizadaResponse> processAndUpload(MultipartFile file, String estructuraJson) throws Exception {
        List<Resource> resources;
        String contentType = file.getContentType();

        if ("application/pdf".equals(contentType)) {
            resources = FileHandlerUtil.pdfToImages(file);
        } else if ("application/zip".equals(contentType) || "application/x-zip-compressed".equals(contentType)) {
            resources = FileHandlerUtil.extractZip(file);
        } else if (contentType != null && contentType.startsWith("image/")) {
            resources = List.of(file.getResource());
        } else {
            throw new IllegalArgumentException("Unsupported file type: " + contentType);
        }

        String requestId = UUID.randomUUID().toString();
        List<PlanillaDigitalizadaResponse> responses = new ArrayList<>();
        Path tmpDir = Files.createTempDirectory("sign-extract-" + requestId);

        try {
            int pageIndex = 1;
            for (Resource res : resources) {
                byte[] imageBytes = res.getInputStream().readAllBytes();

                // 1. LLamada a la IA
                String pageJson = compositeAiService.processSingleImageWithFallback(res, estructuraJson);
                
                // Parse AI response
                JsonNode arr = objectMapper.readTree(pageJson);
                if (!arr.isArray()) {
                    throw new IllegalStateException("AI returned non-array JSON for a page");
                }

                // 2. Extracción de firmas con Python
                List<String> signatureLocalPaths = PythonSignatureUtil.extractSignatures(imageBytes, tmpDir);
                List<String> signatureData = new ArrayList<>();
                for (String localPath : signatureLocalPaths) {
                    byte[] sigBytes = Files.readAllBytes(Paths.get(localPath));
                    String b64 = "data:image/png;base64," + java.util.Base64.getEncoder().encodeToString(sigBytes);
                    signatureData.add(b64);
                }

                // 3. Mapeo a DTOs
                Map<Integer, List<ValorCeldaResponse>> filaMap = new TreeMap<>();
                
                for (JsonNode cellNode : arr) {
                    String colName = cellNode.path("columna").asText();
                    int fila = cellNode.path("fila").asInt();
                    String val = cellNode.hasNonNull("valor") ? cellNode.path("valor").asText() : "";
                    
                    String tipoCampo = getTipoCampoFromEstructura(estructuraJson, colName);
                    
                    ValorCeldaResponse vcr = new ValorCeldaResponse(colName, tipoCampo, val);
                    filaMap.computeIfAbsent(fila, k -> new ArrayList<>()).add(vcr);
                }

                List<FilaDigitalizadaResponse> filas = new ArrayList<>();
                int signatureIndex = 0;
                
                for (Map.Entry<Integer, List<ValorCeldaResponse>> entry : filaMap.entrySet()) {
                    List<ValorCeldaResponse> celdas = entry.getValue();
                    
                    // Inyectar firma si existe el tipo "signature_file"
                    for (ValorCeldaResponse celda : celdas) {
                        if ("signature_file".equals(celda.getTipoCampo())) {
                            if (signatureIndex < signatureData.size()) {
                                celda.setValor(signatureData.get(signatureIndex));
                                signatureIndex++;
                            }
                        }
                    }
                    
                    filas.add(new FilaDigitalizadaResponse(entry.getKey(), celdas));
                }

                responses.add(new PlanillaDigitalizadaResponse(null, null, pageIndex++, filas));
            }

            return responses;
        } finally {
            try {
                Files.walk(tmpDir)
                    .sorted(Comparator.reverseOrder())
                    .map(Path::toFile)
                    .forEach(java.io.File::delete);
            } catch (IOException ignored) {}
        }
    }

    public List<PlanillaDigitalizadaResponse> saveCorrectedData(List<PlanillaDigitalizadaResponse> hojas, String imagenReferenciaB64) throws Exception {
        long presignTtlSeconds = resolvePresignTtlSeconds();

        for (int i = 0; i < hojas.size(); i++) {
            PlanillaDigitalizadaResponse hoja = hojas.get(i);
            String carpeta = hoja.getPlanillaId() != null ? hoja.getPlanillaId().toString() : UUID.randomUUID().toString();

            // Subir imagen de referencia de la planilla digitalizada
            if (imagenReferenciaB64 != null && i == 0) {
                try {
                    String prefix = "data:image/";
                    int commaIdx = imagenReferenciaB64.indexOf(",");
                    String b64Data = commaIdx >= 0 ? imagenReferenciaB64.substring(commaIdx + 1) : imagenReferenciaB64;
                    byte[] refBytes = java.util.Base64.getDecoder().decode(b64Data);
                    String refKey = String.format("planillas/%s/referencia.jpg", carpeta);
                    s3StorageService.upload(refBytes, refKey, "image/jpeg");
                    String refUrl = s3StorageService.presignedGetUrl(refKey, Duration.ofSeconds(presignTtlSeconds));
                    // Guardar URL en la planilla
                    if (hoja.getPlanillaId() != null) {
                        Planilla planilla = planillaRepository.findById(Long.valueOf(hoja.getPlanillaId())).orElse(null);
                        if (planilla != null) {
                            planilla.setUrlReferencia(refUrl);
                            planillaRepository.save(planilla);
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Error subiendo imagen de referencia: " + e.getMessage());
                }
            }
            
            for (int j = 0; j < hoja.getFilas().size(); j++) {
                FilaDigitalizadaResponse fila = hoja.getFilas().get(j);
                
                for (ValorCeldaResponse celda : fila.getValores()) {
                    if (("signature_file".equals(celda.getTipoCampo()) || "file".equals(celda.getTipoCampo())) 
                        && celda.getValor() != null && celda.getValor().startsWith("data:image/png;base64,")) {
                        
                        try {
                            byte[] fileBytes = java.util.Base64.getDecoder().decode(
                                celda.getValor().substring("data:image/png;base64,".length())
                            );
                            String s3Key = String.format("planillas/%s/page_%d/firma_%d.png", 
                                carpeta, hoja.getPaginaNumero(), fila.getIndice());

                            s3StorageService.upload(fileBytes, s3Key, "image/png");
                            String url = s3StorageService.presignedGetUrl(s3Key, Duration.ofSeconds(presignTtlSeconds));
                            celda.setValor(url);
                        } catch (Exception e) {
                            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, 
                                "Error subiendo archivo en hoja " + hoja.getPaginaNumero() + ", fila " + fila.getIndice(), e);
                        }
                    }
                }
            }
        }
        
        return hojas;
    }

    private String getTipoCampoFromEstructura(String estructuraJson, String colName) {
        if (estructuraJson == null || estructuraJson.isEmpty()) return "text";
        try {
            JsonNode root = objectMapper.readTree(estructuraJson);
            JsonNode encabezados = root.path("encabezados");
            if (encabezados.isArray()) {
                for (JsonNode enc : encabezados) {
                    if (enc.path("nombre").asText().equalsIgnoreCase(colName)) {
                        return enc.path("tipo_campo").asText();
                    }
                }
            }
        } catch (Exception e) {}
        return "text";
    }

    private long resolvePresignTtlSeconds() {
        if (presignTtlSecondsRaw == null || presignTtlSecondsRaw.isBlank()) {
            return 3600L;
        }
        try {
            return Long.parseLong(presignTtlSecondsRaw);
        } catch (NumberFormatException ex) {
            return 3600L;
        }
    }

    public EstructuraPropuestaResponse proposeStructureFromImage(Long planillaId, MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Solo se aceptan imágenes (JPEG, PNG, WebP).");
        }

        String rawResponse = compositeAiService.processSingleImageStructureFromImageWithFallback(file.getResource());
        String json = extraerJson(rawResponse);

        List<CampoPropuestoResponse> campos = new ArrayList<>();
        try {
            JsonNode arr = objectMapper.readTree(json);
            if (arr.isArray()) {
                for (JsonNode nodo : arr) {
                    CampoPropuestoResponse c = new CampoPropuestoResponse();
                    c.setNombreCampo(optText(nodo, "nombre_campo"));
                    c.setTipoCampo(optText(nodo, "tipo_campo"));
                    c.setObligatorio(nodo.path("obligatorio").asBoolean(false));
                    JsonNode opcionesNode = nodo.path("opciones");
                    if (opcionesNode.isArray()) {
                        List<String> opciones = new ArrayList<>();
                        for (JsonNode op : opcionesNode) {
                            opciones.add(op.asText());
                        }
                        c.setOpciones(opciones);
                    }
                    campos.add(c);
                }
            }
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Respuesta de IA no parseable: " + e.getMessage());
        }

        validarTipos(campos);

        EstructuraPropuestaResponse resp = new EstructuraPropuestaResponse();
        resp.setPlanillaId(planillaId);
        resp.setCampos(campos);
        return resp;
    }

    private String extraerJson(String raw) {
        if (raw == null) return "[]";
        raw = raw.trim();
        Pattern pattern = Pattern.compile("```(?:json)?\\s*([\\s\\S]*?)\\s*```");
        Matcher matcher = pattern.matcher(raw);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        if (raw.startsWith("{") || raw.startsWith("[")) {
            return raw;
        }
        int firstObj = raw.indexOf('{');
        int firstArr = raw.indexOf('[');
        int start = -1;
        if (firstObj >= 0 && firstArr >= 0) {
            start = Math.min(firstObj, firstArr);
        } else if (firstObj >= 0) {
            start = firstObj;
        } else if (firstArr >= 0) {
            start = firstArr;
        }
        if (start >= 0) {
            return raw.substring(start);
        }
        return "[]";
    }

    private String optText(JsonNode node, String field) {
        JsonNode n = node.path(field);
        return n.isMissingNode() || n.isNull() ? null : n.asText();
    }

    private void validarTipos(List<CampoPropuestoResponse> campos) {
        if (campos == null || campos.isEmpty()) return;
        Set<String> tiposValidos = tipoCampoRepository.findAll().stream()
                .map(TipoCampo::getTipo)
                .collect(Collectors.toSet());
        for (CampoPropuestoResponse c : campos) {
            if (c.getTipoCampo() != null && !tiposValidos.contains(c.getTipoCampo())) {
                throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "Tipo de campo no válido propuesto por IA: " + c.getTipoCampo());
            }
        }
    }
}
