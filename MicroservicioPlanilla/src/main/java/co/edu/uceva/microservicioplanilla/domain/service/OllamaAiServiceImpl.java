package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;

/**
 * Implementación de IAiModelService para Ollama local/remoto.
 * Usa RestTemplate directo (igual que Groq) para leer la URL 
 * dinámicamente desde DynamicAiConfigService en cada petición,
 * permitiendo cambiar de servidor Ollama en caliente sin reiniciar.
 *
 * El modelo usado es "ocr-masivo" (basado en glm-ocr con Modelfile personalizado).
 * GLM-OCR tiene prompts limitados:
 *   - Document Parsing: "Text Recognition:", "Table Recognition:", "Formula Recognition:"
 *   - Information Extraction: "请按下列JSON格式输出图中信息:" + esquema JSON
 */
@Service("ollamaAiService")
@RequiredArgsConstructor
public class OllamaAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private RestTemplate getRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(java.time.Duration.ofSeconds(30));
        factory.setReadTimeout(java.time.Duration.ofSeconds(300)); // 5 min para modelos grandes
        return new RestTemplate(factory);
    }

    @Override
    public String getProviderName() {
        return "Ollama (RestTemplate - " + configService.getOllamaModel() + ")";
    }

    @Override
    public String generateResponse(List<Resource> images) {
        // Limitación de GLM-OCR: Para "Document Parsing" solo soporta strings exactos.
        // Como son planillas, usamos "Table Recognition:"
        return callOllamaApi(images, "Table Recognition:");
    }

    @Override
    public String extractStructure(List<Resource> images) {
        // Limitación de GLM-OCR: Para "Information Extraction" exige un prompt estricto 
        // indicando el formato JSON esperado precedido por la instrucción en chino:
        String promptText = """
                请按下列JSON格式输出图中信息:
                {
                  "encabezados": [
                    {
                      "nombre": "Nombre de la columna",
                      "tipo_campo": "texto | numerico | fecha | desplegable | checkbox | radio | area_texto | archivo | firma",
                      "opciones": ["Opcion 1 si aplica", "Opcion 2 si aplica"] 
                    }
                  ]
                }
                """;
        return callOllamaApi(images, promptText);
    }

    private String callOllamaApi(List<Resource> images, String promptText) {
        String baseUrl = configService.getOllamaBaseUrl();

        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Ollama URL is not configured.");
        }

        // Normalizar URL: quitar trailing slash
        if (baseUrl.endsWith("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }

        try {
            // 1. Preprocesar y codificar imagen a Base64
            Resource imageResource = ImagePreprocessor.preprocessImage(images.get(0));
            byte[] imageBytes;
            try (InputStream is = imageResource.getInputStream()) {
                imageBytes = is.readAllBytes();
            }
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            // 2. Construir payload para Ollama API (/api/chat)
            // Ollama espera: { model, messages: [{role, content, images: [base64]}], stream: false }
            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", promptText);
            message.put("images", List.of(base64Image));

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", configService.getOllamaModel());
            payload.put("messages", List.of(message));
            payload.put("stream", false);

            // Opciones para mayor contexto (según Modelfile del usuario)
            Map<String, Object> options = new HashMap<>();
            options.put("num_ctx", 65536);
            options.put("num_batch", 4096);
            options.put("temperature", 0.1);
            payload.put("options", options);

            // 3. Configurar headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

            // 4. Llamar a Ollama
            String endpoint = baseUrl + "/api/chat";
            System.out.println("[*] Ollama REST → " + endpoint + " (model=" + configService.getOllamaModel() + ")");

            String responseJson = getRestTemplate().postForObject(endpoint, requestEntity, String.class);

            // 5. Parsear respuesta de Ollama
            return parseOllamaResponse(responseJson);

        } catch (IOException e) {
            throw new RuntimeException("Error processing image for Ollama OCR: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("Error calling Ollama API: " + e.getMessage(), e);
        }
    }

    private String parseOllamaResponse(String rawResponse) {
        if (rawResponse == null) return "";
        try {
            JsonNode rootNode = objectMapper.readTree(rawResponse);

            // Ollama /api/chat format: { message: { content: "..." } }
            JsonNode messageNode = rootNode.path("message");
            if (!messageNode.isMissingNode() && messageNode.has("content")) {
                return messageNode.get("content").asText();
            }

            // Fallback: OpenAI-compatible format (choices)
            JsonNode choices = rootNode.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                return choices.get(0).path("message").path("content").asText();
            }

            // Fallback: response field (older Ollama /api/generate)
            if (rootNode.has("response")) {
                return rootNode.get("response").asText();
            }

            return rawResponse;
        } catch (Exception e) {
            return rawResponse;
        }
    }
}