package co.edu.uceva.microservicioplanilla.domain.service.ai.providers;

import co.edu.uceva.microservicioplanilla.domain.service.ai.IAiModelService;
import co.edu.uceva.microservicioplanilla.domain.service.ai.DynamicAiConfigService;
import co.edu.uceva.microservicioplanilla.domain.service.ai.AiPromptFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.io.InputStream;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service("groqAiService")
@AllArgsConstructor
public class GroqAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;
    private final AiPromptFactory promptFactory;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String getProviderName() {
        return "Groq (" + configService.getGroqModel() + ")";
    }

    @Override
    public String extractText(List<Resource> images, String estructuraJson) {
        String promptText = promptFactory.buildTextRecognitionPrompt(estructuraJson);
        return callGroqApi(images, promptText);
    }

    @Override
    public String extractStructure(List<Resource> images, String tiposPermitidos) {
        String promptText = promptFactory.buildStructureExtractionPrompt(tiposPermitidos);
        return callGroqApi(images, promptText);
    }

    private String callGroqApi(List<Resource> images, String promptText) {
        String baseUrl = configService.getGroqUrl();
        String apiKey = configService.getGroqToken();
        String modelName = configService.getGroqModel();

        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Groq URL is not configured.");
        }
        if (apiKey == null || apiKey.isEmpty()) {
            throw new IllegalStateException("Groq API Key is not configured.");
        }

        try {
            // Read first image and convert to Base64
            Resource imageResource = images.get(0);
            byte[] imageBytes;
            try (InputStream is = imageResource.getInputStream()) {
                imageBytes = is.readAllBytes();
            }
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            // Construct exact JSON payload for Groq
            Map<String, Object> textContent = new HashMap<>();
            textContent.put("type", "text");
            textContent.put("text", promptText);

            Map<String, String> imageUrlMap = new HashMap<>();
            imageUrlMap.put("url", "data:image/jpeg;base64," + base64Image);

            Map<String, Object> imageContent = new HashMap<>();
            imageContent.put("type", "image_url");
            imageContent.put("image_url", imageUrlMap);

            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", List.of(textContent, imageContent));

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", modelName);
            payload.put("messages", List.of(message));
            payload.put("temperature", 0.1);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

            // Ensure the URL ends with /chat/completions
            String endpoint = baseUrl.endsWith("/chat/completions") ? baseUrl : baseUrl + "/chat/completions";

            String responseJson = restTemplate.postForObject(endpoint, requestEntity, String.class);
            
            // Parse Groq response
            JsonNode rootNode = objectMapper.readTree(responseJson);
            JsonNode choices = rootNode.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                return choices.get(0).path("message").path("content").asText();
            }
            return "Error: No content in Groq response.";

        } catch (IOException e) {
            throw new RuntimeException("Error processing image for Groq OCR", e);
        } catch (Exception e) {
            throw new RuntimeException("Error calling Groq API: " + e.getMessage(), e);
        }
    }
}
