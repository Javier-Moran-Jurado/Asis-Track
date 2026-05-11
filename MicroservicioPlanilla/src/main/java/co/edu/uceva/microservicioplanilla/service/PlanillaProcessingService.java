package co.edu.uceva.microservicioplanilla.service;

import co.edu.uceva.microservicioplanilla.domain.model.*;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IFilaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import co.edu.uceva.microservicioplanilla.domain.service.ICampoService;
import co.edu.uceva.microservicioplanilla.domain.service.IFilaService;
import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
    private final IDatoRepository datoRepository;
    private final IFilaRepository filaRepository;
    private final IFilaService filaService;
    private final ICampoService campoService;

    public PlanillaProcessingService(
        S3StorageService s3StorageService,
        CompositeAiService compositeAiService,
        ObjectMapper objectMapper,
        ITipoCampoRepository tipoCampoRepository,
        IPlanillaRepository planillaRepository,
        IDatoRepository datoRepository,
        IFilaRepository filaRepository,
        IFilaService filaService,
        ICampoService campoService
    ) {
        this.s3StorageService = s3StorageService;
        this.compositeAiService = compositeAiService;
        this.objectMapper = objectMapper;
        this.tipoCampoRepository = tipoCampoRepository;
        this.planillaRepository = planillaRepository;
        this.datoRepository = datoRepository;
        this.filaRepository = filaRepository;
        this.filaService = filaService;
        this.campoService = campoService;
    }

    @Transactional
    public PlanillaResponse digitalizarYGuardar(MultipartFile file, Long planillaId, String estructuraJson) throws Exception {
        Planilla planilla = planillaRepository.findById(planillaId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Planilla no encontrada: " + planillaId));

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

        Path tmpDir = Files.createTempDirectory("sign-extract-" + UUID.randomUUID());

        try {
            byte[] sourceImageBytes = resources.get(0).getInputStream().readAllBytes();

            datoRepository.deleteByPlanillaId(planillaId);
            filaRepository.deleteByPlanillaId(planillaId);

            int filaIndiceOffset = 0;
            int pageIndex = 1;
            for (Resource res : resources) {
                byte[] imageBytes = res.getInputStream().readAllBytes();

                String pageJson = compositeAiService.processSingleImageWithFallback(res, estructuraJson);
                JsonNode arr = objectMapper.readTree(pageJson);
                if (!arr.isArray()) {
                    throw new IllegalStateException("AI returned non-array JSON for a page");
                }

                List<String> signatureLocalPaths = PythonSignatureUtil.extractSignatures(imageBytes, tmpDir);
                List<byte[]> signatureBytes = new ArrayList<>();
                for (String localPath : signatureLocalPaths) {
                    signatureBytes.add(Files.readAllBytes(Paths.get(localPath)));
                }

                Map<Integer, List<CellData>> filaMap = new TreeMap<>();
                for (JsonNode cellNode : arr) {
                    String colName = cellNode.path("columna").asText();
                    int filaIdx = cellNode.path("fila").asInt();
                    String val = cellNode.hasNonNull("valor") ? cellNode.path("valor").asText() : "";
                    String tipoCampo = getTipoCampoFromEstructura(estructuraJson, colName);
                    filaMap.computeIfAbsent(filaIdx, k -> new ArrayList<>()).add(new CellData(colName, tipoCampo, val));
                }

                List<Campo> campos = campoService.findByPlanillaId(planillaId);
                int signatureIndex = 0;

                for (Map.Entry<Integer, List<CellData>> entry : filaMap.entrySet()) {
                    List<DatoRequest> datosFila = new ArrayList<>();
                    int filaIndice = filaIndiceOffset + entry.getKey();

                    for (CellData cell : entry.getValue()) {
                        String valorFinal = cell.valor;

                        if ("signature_file".equals(cell.tipoCampo) && signatureIndex < signatureBytes.size()) {
                            byte[] sigBytes = signatureBytes.get(signatureIndex);
                            String s3Key = String.format("planillas/%d/page_%d/firma_%d.png", planillaId, pageIndex, filaIndice);
                            s3StorageService.upload(sigBytes, s3Key, "image/png");
                            valorFinal = s3StorageService.publicUrl(s3Key);
                            signatureIndex++;
                        }

                        Campo campoMatch = campos.stream()
                                .filter(c -> c.getNombreCampo().equalsIgnoreCase(cell.colName))
                                .findFirst().orElse(null);

                        if (campoMatch != null) {
                            DatoRequest dr = new DatoRequest();
                            dr.setCampoId(campoMatch.getId());
                            dr.setPosicion(0);
                            dr.setInformacion(valorFinal);
                            datosFila.add(dr);
                        }
                    }

                    FilaRequest filaReq = new FilaRequest();
                    filaReq.setPlanillaId(planillaId);
                    filaReq.setIndice(filaIndice);
                    filaReq.setDatos(datosFila);
                    filaService.create(filaReq);
                }

                filaIndiceOffset += filaMap.size();
                pageIndex++;
            }

            if (resources.size() > 0) {
                String refKey = String.format("planillas/%d/referencia.jpg", planillaId);
                s3StorageService.upload(sourceImageBytes, refKey, "image/jpeg");
                planilla.setUrlReferencia(s3StorageService.publicUrl(refKey));
                planillaRepository.save(planilla);
            }

            return PlanillaResponse.from(planillaRepository.findById(planillaId).orElse(planilla));
        } finally {
            try {
                Files.walk(tmpDir)
                    .sorted(Comparator.reverseOrder())
                    .map(Path::toFile)
                    .forEach(java.io.File::delete);
            } catch (IOException ignored) {}
        }
    }

    @Transactional
    public List<CampoResponse> proposeAndSaveStructure(Long planillaId, MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Solo se aceptan imágenes.");
        }

        String rawResponse = compositeAiService.processSingleImageStructureFromImageWithFallback(file.getResource());
        String json = extraerJson(rawResponse);

        List<CampoRequest> camposToSave = new ArrayList<>();
        try {
            JsonNode arr = objectMapper.readTree(json);
            if (arr.isArray()) {
                for (JsonNode nodo : arr) {
                    CampoRequest cr = new CampoRequest();
                    cr.setPlanillaId(planillaId);
                    cr.setNombreCampo(optText(nodo, "nombre_campo"));
                    String tipoCampoStr = optText(nodo, "tipo_campo");
                    TipoCampo tc = tipoCampoRepository.findAll().stream()
                            .filter(t -> t.getTipo().equalsIgnoreCase(tipoCampoStr))
                            .findFirst()
                            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                                    "Tipo de campo no válido: " + tipoCampoStr));
                    cr.setTipoCampoId(tc.getId());
                    cr.setObligatorio(nodo.path("obligatorio").asBoolean(false));
                    camposToSave.add(cr);
                }
            }
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Respuesta de IA no parseable: " + e.getMessage());
        }

        return campoService.saveAll(camposToSave).stream().map(CampoResponse::from).toList();
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

    private static class CellData {
        String colName;
        String tipoCampo;
        String valor;

        CellData(String colName, String tipoCampo, String valor) {
            this.colName = colName;
            this.tipoCampo = tipoCampo;
            this.valor = valor;
        }
    }
}
