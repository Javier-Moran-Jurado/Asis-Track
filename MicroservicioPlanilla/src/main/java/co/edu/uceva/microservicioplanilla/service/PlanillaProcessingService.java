package co.edu.uceva.microservicioplanilla.service;

import co.edu.uceva.microservicioplanilla.domain.service.CompositeAiService;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

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

    public String processAndUpload(MultipartFile file) throws Exception {
        List<Resource> resources;
        String contentType = file.getContentType();

        if ("application/pdf".equals(contentType)) {
            resources = FileHandlerUtil.pdfToImages(file);
        } else if ("application/zip".equals(contentType)) {
            resources = FileHandlerUtil.extractZip(file);
        } else if (contentType != null && (contentType.startsWith("image/"))) {
            resources = List.of(file.getResource());
        } else {
            throw new IllegalArgumentException(
                "Unsupported file type: " + contentType
            );
        }

        String requestId = UUID.randomUUID().toString();
        ArrayNode merged = objectMapper.createArrayNode();

        Path tmpDir = Files.createTempDirectory("sign-extract-" + requestId);

        try {
            int pageIndex = 0;
            for (Resource res : resources) {
                byte[] imageBytes = res.getInputStream().readAllBytes();

                String filename =
                    res.getFilename() == null
                        ? ("page_" + (pageIndex + 1) + ".jpg")
                        : res.getFilename();
                String sourceData = "";
                if (uploadSourceImages) {
                    sourceData =
                        "data:image/jpeg;base64," +
                        java.util.Base64.getEncoder().encodeToString(
                            imageBytes
                        );
                }

                // Run OCR for this single image
                String pageJson =
                    compositeAiService.processSingleImageWithFallback(res);
                JsonNode arr = objectMapper.readTree(pageJson);
                if (!arr.isArray()) {
                    throw new IllegalStateException(
                        "AI returned non-array JSON for a page"
                    );
                }

                // Extract signatures for this page
                List<String> signatureLocalPaths =
                    PythonSignatureUtil.extractSignatures(imageBytes, tmpDir);
                List<String> signatureData = new ArrayList<>();
                for (String localPath : signatureLocalPaths) {
                    byte[] sigBytes = Files.readAllBytes(Paths.get(localPath));
                    String b64 =
                        "data:image/png;base64," +
                        java.util.Base64.getEncoder().encodeToString(sigBytes);
                    signatureData.add(b64);
                }

                // Map signatures to rows by index and add source
                int rowIndex = 0;
                for (JsonNode rowNode : arr) {
                    if (!rowNode.isObject()) continue;
                    ObjectNode obj = (ObjectNode) rowNode;
                    String firmaB64 = "";
                    if (rowIndex < signatureData.size()) {
                        firmaB64 = signatureData.get(rowIndex);
                    }
                    obj.put("firma", firmaB64);
                    if (uploadSourceImages) {
                        obj.put("source", sourceData);
                    }
                    merged.add(obj);
                    rowIndex++;
                }

                pageIndex++;
            }

            return objectMapper.writeValueAsString(merged);
        } finally {
            // cleanup temporary extraction directory
            try {
                Files.walk(tmpDir)
                    .map(Path::toFile)
                    .sorted((a, b) -> -a.compareTo(b))
                    .forEach(java.io.File::delete);
            } catch (IOException ignored) {}
        }
    }

    public String saveCorrectedData(String jsonData) throws Exception {
        JsonNode root = objectMapper.readTree(jsonData);
        if (!root.isArray()) {
            throw new IllegalArgumentException("Expected a JSON array");
        }

        String requestId = UUID.randomUUID().toString();
        ArrayNode merged = objectMapper.createArrayNode();
        long presignTtlSeconds = resolvePresignTtlSeconds();

        int rowIndex = 0;
        for (JsonNode rowNode : root) {
            if (!rowNode.isObject()) continue;
            ObjectNode obj = (ObjectNode) rowNode;

            // Upload signature if present and is base64
            if (obj.has("firma") && obj.get("firma").isTextual()) {
                String firmaData = obj.get("firma").asText();
                if (firmaData.startsWith("data:image/png;base64,")) {
                    byte[] sigBytes = java.util.Base64.getDecoder().decode(
                        firmaData.substring("data:image/png;base64,".length())
                    );
                    String sigKey = String.format(
                        "planillas/%s/signatures/row_%d_firma.png",
                        requestId,
                        rowIndex
                    );
                    s3StorageService.upload(sigBytes, sigKey, "image/png");
                    String sigUrl = s3StorageService.presignedGetUrl(
                        sigKey,
                        Duration.ofSeconds(presignTtlSeconds)
                    );
                    obj.put("firma", sigUrl);
                }
            }

            // Upload source if present and is base64
            if (obj.has("source") && obj.get("source").isTextual()) {
                String sourceData = obj.get("source").asText();
                if (sourceData.startsWith("data:image/jpeg;base64,")) {
                    byte[] sourceBytes = java.util.Base64.getDecoder().decode(
                        sourceData.substring("data:image/jpeg;base64,".length())
                    );
                    String sourceKey = String.format(
                        "planillas/%s/sources/row_%d_source.jpg",
                        requestId,
                        rowIndex
                    );
                    s3StorageService.upload(
                        sourceBytes,
                        sourceKey,
                        "image/jpeg"
                    );
                    String sourceUrl = s3StorageService.presignedGetUrl(
                        sourceKey,
                        Duration.ofSeconds(presignTtlSeconds)
                    );
                    obj.put("source", sourceUrl);
                }
            }

            merged.add(obj);
            rowIndex++;
        }

        return objectMapper.writeValueAsString(merged);
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
