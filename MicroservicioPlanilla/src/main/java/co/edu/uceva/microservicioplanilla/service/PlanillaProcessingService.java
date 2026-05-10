package co.edu.uceva.microservicioplanilla.service;

import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.PlanillaDigitalizadaResponse;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.FilaDigitalizadaResponse;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.ValorCeldaResponse;
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

@Service
public class PlanillaProcessingService {

    private final S3StorageService s3StorageService;
    private final CompositeAiService compositeAiService;
    private final ObjectMapper objectMapper;

    @Value("${s3.presign-ttl-seconds:3600}")
    private String presignTtlSecondsRaw;

    @Value("${s3.upload-sources:false}")
    private boolean uploadSourceImages;

    public PlanillaProcessingService(
        S3StorageService s3StorageService,
        CompositeAiService compositeAiService,
        ObjectMapper objectMapper
    ) {
        this.s3StorageService = s3StorageService;
        this.compositeAiService = compositeAiService;
        this.objectMapper = objectMapper;
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

                responses.add(new PlanillaDigitalizadaResponse(pageIndex++, filas));
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

    public List<PlanillaDigitalizadaResponse> saveCorrectedData(List<PlanillaDigitalizadaResponse> hojas) throws Exception {
        String requestId = UUID.randomUUID().toString();
        long presignTtlSeconds = resolvePresignTtlSeconds();

        for (int i = 0; i < hojas.size(); i++) {
            PlanillaDigitalizadaResponse hoja = hojas.get(i);
            
            for (int j = 0; j < hoja.getFilas().size(); j++) {
                FilaDigitalizadaResponse fila = hoja.getFilas().get(j);
                
                for (ValorCeldaResponse celda : fila.getValores()) {
                    if (("signature_file".equals(celda.getTipoCampo()) || "file".equals(celda.getTipoCampo())) 
                        && celda.getValor() != null && celda.getValor().startsWith("data:image/png;base64,")) {
                        
                        try {
                            byte[] fileBytes = java.util.Base64.getDecoder().decode(
                                celda.getValor().substring("data:image/png;base64,".length())
                            );
                            String s3Key = String.format("planillas/%s/page_%d/row_%d_%s.png", 
                                requestId, hoja.getPaginaNumero(), fila.getIndice(), celda.getNombreCampo().replaceAll("[^a-zA-Z0-9.-]", "_"));
                            
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
}
