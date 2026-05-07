package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import co.edu.uceva.microservicioplanilla.utils.SpellCheckerUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Service("huggingFaceAiService")
@RequiredArgsConstructor
public class HuggingFaceAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String getProviderName() {
        return "Hugging Face (GLM-OCR / Zai)";
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
        return callHfApi(images, promptText);
    }

    @Override
    public String generateResponse(List<Resource> images) {
        // Limitación de GLM-OCR: Para "Document Parsing" solo soporta strings exactos:
        // "Text Recognition:", "Formula Recognition:" o "Table Recognition:"
        String promptText = "Table Recognition:";
        return callHfApi(images, promptText);
    }

    private String callHfApi(List<Resource> images, String promptText) {
        String baseUrl = configService.getHfUrl();
        String apiKey = configService.getHfToken();

        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Hugging Face URL is not configured.");
        }
        if (apiKey == null || apiKey.isEmpty()) {
            throw new IllegalStateException("Hugging Face API Key is not configured.");
        }

        try {
            Resource imageResource = ImagePreprocessor.preprocessImage(images.get(0));
            byte[] imageBytes = imageResource.getInputStream().readAllBytes();
            java.util.Base64.Encoder encoder = java.util.Base64.getEncoder();
            String base64Image = encoder.encodeToString(imageBytes);

            // Construct exact JSON payload compatible with OpenAI/Zhipu/HF Inference Endpoints
            java.util.Map<String, Object> textContent = new java.util.HashMap<>();
            textContent.put("type", "text");
            textContent.put("text", promptText);

            java.util.Map<String, String> imageUrlMap = new java.util.HashMap<>();
            imageUrlMap.put("url", "data:image/jpeg;base64," + base64Image);

            java.util.Map<String, Object> imageContent = new java.util.HashMap<>();
            imageContent.put("type", "image_url");
            imageContent.put("image_url", imageUrlMap);

            java.util.Map<String, Object> message = new java.util.HashMap<>();
            message.put("role", "user");
            message.put("content", List.of(textContent, imageContent));

            java.util.Map<String, Object> payload = new java.util.HashMap<>();
            // Use a default model name or take from config if available (we will hardcode a fallback if needed)
            payload.put("model", "glm-4v"); 
            payload.put("messages", List.of(message));
            payload.put("temperature", 0.1);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<java.util.Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

            String responseJson = restTemplate.postForObject(baseUrl, requestEntity, String.class);
            return parseHfResponse(responseJson);

        } catch (java.io.IOException e) {
            throw new RuntimeException("Error processing image for Hugging Face OCR", e);
        } catch (Exception e) {
            throw new RuntimeException("Error calling Hugging Face API: " + e.getMessage(), e);
        }
    }

    private String parseHfResponse(String rawResponse) {
        if (rawResponse == null) return "";
        try {
            JsonNode rootNode = objectMapper.readTree(rawResponse);
            
            // Standard OpenAI/GLM Chat Completions format
            JsonNode choices = rootNode.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                return choices.get(0).path("message").path("content").asText();
            }

            // Fallbacks for direct GLM-OCR or other schemas
            if (rootNode.has("text")) {
                return rootNode.get("text").asText();
            } else if (rootNode.has("response")) {
                return rootNode.get("response").asText();
            } else if (rootNode.has("text_content")) {
                return rootNode.get("text_content").asText();
            }
            
            return rawResponse;
        } catch (Exception e) {
            return rawResponse;
        }
    }
}
