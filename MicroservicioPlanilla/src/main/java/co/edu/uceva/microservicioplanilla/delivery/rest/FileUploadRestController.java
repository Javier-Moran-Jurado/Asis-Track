package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.service.S3StorageService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class FileUploadRestController {

    private final S3StorageService s3StorageService;

    public FileUploadRestController(S3StorageService s3StorageService) {
        this.s3StorageService = s3StorageService;
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping("/upload")
    public ResponseEntity<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String key = String.format("uploads/%d-%s%s", Instant.now().getEpochSecond(), UUID.randomUUID(), extension);

        s3StorageService.upload(file.getBytes(), key, file.getContentType());
        String url = s3StorageService.publicUrl(key);

        return ResponseEntity.ok(Map.of("url", url, "key", key));
    }
}
