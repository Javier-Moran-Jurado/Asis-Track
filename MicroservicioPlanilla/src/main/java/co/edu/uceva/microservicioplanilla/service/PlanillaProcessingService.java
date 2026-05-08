package co.edu.uceva.microservicioplanilla.service;

import co.edu.uceva.microservicioplanilla.domain.service.CompositeAiService;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class PlanillaProcessingService {

    private final S3StorageService s3StorageService;
    private final CompositeAiService compositeAiService;
    private final ObjectMapper objectMapper;

    @Value("${s3.presign-ttl-seconds:3600}")
    private String presignTtlSecondsRaw;

    @Value("${s3.upload-sources:false}")
    private boolean uploadSourceImages;

    public PlanillaProcessingService(S3StorageService s3StorageService, CompositeAiService compositeAiService, ObjectMapper objectMapper) {
        this.s3StorageService = s3StorageService;
        this.compositeAiService = compositeAiService;
        this.objectMapper = objectMapper;
    }

    public String processAndUpload(MultipartFile file) throws Exception {
        List<Resource> resources;
        String contentType = file.getContentType();

        long presignTtlSeconds = resolvePresignTtlSeconds();

        if ("application/pdf".equals(contentType)) {
            resources = FileHandlerUtil.pdfToImages(file);
        } else if ("application/zip".equals(contentType)) {
            resources = FileHandlerUtil.extractZip(file);
        } else if (contentType != null && (contentType.startsWith("image/"))) {
            resources = List.of(file.getResource());
        } else {
            throw new IllegalArgumentException("Unsupported file type: " + contentType);
        }

        String requestId = UUID.randomUUID().toString();
        ArrayNode merged = objectMapper.createArrayNode();

        Path tmpDir = Files.createTempDirectory("sign-extract-" + requestId);

        try {
            int pageIndex = 0;
            for (Resource res : resources) {
                byte[] imageBytes = res.getInputStream().readAllBytes();

                String filename = res.getFilename() == null ? ("page_" + (pageIndex + 1) + ".jpg") : res.getFilename();
                String sourceUrl = "";
                if (uploadSourceImages) {
                    String sourceKey = String.format("planillas/%s/sources/%s", requestId, filename);
                    s3StorageService.upload(imageBytes, sourceKey, "image/jpeg");
                    sourceUrl = s3StorageService.presignedGetUrl(sourceKey, Duration.ofSeconds(presignTtlSeconds));
                }

                // Run OCR for this single image
                String pageJson = compositeAiService.processSingleImageWithFallback(res);
                JsonNode arr = objectMapper.readTree(pageJson);
                if (!arr.isArray()) {
                    throw new IllegalStateException("AI returned non-array JSON for a page");
                }

                // Extract signatures for this page
                List<String> signatureLocalPaths = PythonSignatureUtil.extractSignatures(imageBytes, tmpDir);
                List<String> signatureUrls = new ArrayList<>();
                int sigIdx = 0;
                for (String localPath : signatureLocalPaths) {
                    byte[] sigBytes = Files.readAllBytes(Paths.get(localPath));
                    String sigKey = String.format("planillas/%s/signatures/page_%d_firma_%d.png", requestId, pageIndex + 1, ++sigIdx);
                    s3StorageService.upload(sigBytes, sigKey, "image/png");
                    String sigUrl = s3StorageService.presignedGetUrl(sigKey, Duration.ofSeconds(presignTtlSeconds));
                    signatureUrls.add(sigUrl);
                }

                // Map signatures to rows by index and add source
                int rowIndex = 0;
                for (JsonNode rowNode : arr) {
                    if (!rowNode.isObject()) continue;
                    ObjectNode obj = (ObjectNode) rowNode;
                    String firmaUrl = "";
                    if (rowIndex < signatureUrls.size()) {
                        firmaUrl = signatureUrls.get(rowIndex);
                    }
                    obj.put("firma", firmaUrl);
                    if (uploadSourceImages) {
                        obj.put("source", sourceUrl);
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
            } catch (IOException ignored) {
            }
        }
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
