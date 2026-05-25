package co.edu.uceva.microservicioplanilla.utils;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

public class PythonSignatureUtil {

    private static final Logger log = LoggerFactory.getLogger(PythonSignatureUtil.class);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final Duration DEFAULT_TIMEOUT = Duration.ofMinutes(2);
    private static final String EXTRACCION_SERVICE_URL = System.getenv().getOrDefault(
        "EXTRACCION_SERVICE_URL",
        "http://extraccion-service:8000"
    );

    private PythonSignatureUtil() {}

    private static RestTemplate createRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) DEFAULT_TIMEOUT.toMillis());
        factory.setReadTimeout((int) DEFAULT_TIMEOUT.toMillis());
        return new RestTemplate(factory);
    }

    public static List<String> extractSignatures(
        MultipartFile imageFile,
        Path outputDir
    ) throws IOException {
        return extractSignatures(imageFile.getBytes(), outputDir);
    }

    public static List<String> extractSignatures(
        byte[] imageBytes,
        Path outputDir
    ) throws IOException {
        Objects.requireNonNull(imageBytes, "imageBytes no puede ser nulo");

        log.info("[PythonSignatureUtil] Iniciando extracción de firmas via HTTP. URL: {}/extract", EXTRACCION_SERVICE_URL);
        Path normalizedOutputDir = resolveOutputDir(outputDir);
        Files.createDirectories(normalizedOutputDir);

        RestTemplate restTemplate = createRestTemplate();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        ByteArrayResource imageResource = new ByteArrayResource(imageBytes) {
            @Override
            public String getFilename() {
                return "image.png";
            }
        };

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", imageResource);

        HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

        String url = EXTRACCION_SERVICE_URL + "/extract";
        ResponseEntity<String> response;
        try {
            response = restTemplate.exchange(url, HttpMethod.POST, requestEntity, String.class);
        } catch (Exception e) {
            log.error("[PythonSignatureUtil] Error llamando al microservicio de extracción: {}", e.getMessage(), e);
            throw new IllegalStateException("Error llamando al microservicio de extracción: " + e.getMessage(), e);
        }

        if (response.getStatusCode() != HttpStatus.OK) {
            log.error("[PythonSignatureUtil] El microservicio devolvió código {}: {}", response.getStatusCode(), response.getBody());
            throw new IllegalStateException("El microservicio de extracción devolvió error HTTP " + response.getStatusCode());
        }

        String responseBody = response.getBody();
        if (responseBody == null || responseBody.isBlank()) {
            log.error("[PythonSignatureUtil] El microservicio no devolvió respuesta.");
            throw new IllegalStateException("El extractor de firmas no devolvió salida JSON");
        }

        JsonNode rootNode = OBJECT_MAPPER.readTree(responseBody);
        if (rootNode.hasNonNull("error")) {
            log.error("[PythonSignatureUtil] Error devuelto en el JSON: {}", rootNode.get("error").asText());
            throw new IllegalStateException(rootNode.get("error").asText());
        }

        JsonNode signaturesNode = rootNode.path("signatures");
        List<String> signaturePaths = new ArrayList<>();
        if (signaturesNode.isArray()) {
            int idx = 0;
            for (JsonNode sigNode : signaturesNode) {
                String b64 = sigNode.path("base64").asText();
                if (b64 == null || b64.isBlank()) continue;

                byte[] sigBytes = Base64.getDecoder().decode(b64);
                Path sigPath = normalizedOutputDir.resolve("firma_" + String.format("%02d", idx + 1) + ".jpg");
                Files.write(sigPath, sigBytes);
                signaturePaths.add(sigPath.toString());
                idx++;
            }
        }

        log.info("[PythonSignatureUtil] Extracción completada. {} firmas guardadas en {}", signaturePaths.size(), normalizedOutputDir);
        return signaturePaths;
    }

    public static String cropSignature(
        String base64Image,
        int x,
        int y,
        int w,
        int h,
        Path outputDir
    ) throws IOException {
        Objects.requireNonNull(base64Image, "base64Image no puede ser nulo");

        Path normalizedOutputDir = resolveOutputDir(outputDir);
        Files.createDirectories(normalizedOutputDir);

        String pureBase64 = base64Image;
        if (base64Image.contains(",")) {
            pureBase64 = base64Image.split(",")[1];
        }

        byte[] imageBytes = Base64.getDecoder().decode(pureBase64);

        RestTemplate restTemplate = createRestTemplate();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        ByteArrayResource imageResource = new ByteArrayResource(imageBytes) {
            @Override
            public String getFilename() {
                return "image.png";
            }
        };

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", imageResource);

        String url = String.format(
            "%s/crop?x=%d&y=%d&w=%d&h=%d",
            EXTRACCION_SERVICE_URL, x, y, w, h
        );

        HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
        ResponseEntity<String> response;
        try {
            response = restTemplate.exchange(url, HttpMethod.POST, requestEntity, String.class);
        } catch (Exception e) {
            throw new IllegalStateException("Error llamando al microservicio de recorte: " + e.getMessage(), e);
        }

        if (response.getStatusCode() != HttpStatus.OK) {
            throw new IllegalStateException("El microservicio de recorte devolvió error HTTP " + response.getStatusCode());
        }

        String responseBody = response.getBody();
        if (responseBody == null || responseBody.isBlank()) {
            throw new IllegalStateException("El extractor no devolvió la firma recortada");
        }

        JsonNode rootNode = OBJECT_MAPPER.readTree(responseBody);
        if (rootNode.hasNonNull("error")) {
            throw new IllegalStateException(rootNode.get("error").asText());
        }

        String b64 = rootNode.path("base64").asText();
        if (b64 == null || b64.isBlank()) {
            throw new IllegalStateException("El extractor no devolvió la firma recortada");
        }

        byte[] cropBytes = Base64.getDecoder().decode(b64);
        Path cropPath = normalizedOutputDir.resolve("custom_crop.png");
        Files.write(cropPath, cropBytes);
        return cropPath.toString();
    }

    private static Path resolveOutputDir(Path outputDir) {
        if (outputDir == null) {
            return Paths.get("target", "signature-output")
                .toAbsolutePath()
                .normalize();
        }
        return outputDir.toAbsolutePath().normalize();
    }
}
