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
    public String generateResponse(List<Resource> images) {
        StringBuilder fullText = new StringBuilder();

        for (Resource image : images) {
            try {
                // 1. Preprocesar imagen
                Resource processedImg = ImagePreprocessor.preprocessImage(image);
                byte[] imageBytes = processedImg.getInputStream().readAllBytes();

                // 2. Configurar cabeceras
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.IMAGE_JPEG);
                headers.setBearerAuth(configService.getHfToken());

                // 3. Crear petición
                HttpEntity<byte[]> requestEntity = new HttpEntity<>(imageBytes, headers);

                // 4. Llamar a la API
                String rawResponse = restTemplate.postForObject(configService.getHfUrl(), requestEntity, String.class);

                // 5. Parsear respuesta (Dependiendo de la estructura de GLM-OCR)
                String extractedText = parseHfResponse(rawResponse);

                // 6. Corrección ortográfica
                String corrected = SpellCheckerUtil.correctText(extractedText);
                fullText.append(corrected).append("\n\n");

            } catch (Exception e) {
                throw new RuntimeException("Error en Hugging Face API: " + e.getMessage(), e);
            }
        }
        return fullText.toString().trim();
    }

    private String parseHfResponse(String rawResponse) {
        if (rawResponse == null) return "";
        try {
            JsonNode rootNode = objectMapper.readTree(rawResponse);
            
            // Si la respuesta tiene un campo text o response, lo sacamos.
            if (rootNode.has("text")) {
                return rootNode.get("text").asText();
            } else if (rootNode.has("response")) {
                return rootNode.get("response").asText();
            } else if (rootNode.has("text_content")) {
                return rootNode.get("text_content").asText();
            }
            
            // Si no es un JSON conocido, devolverlo crudo o buscar nodos de texto.
            return rawResponse;
        } catch (Exception e) {
            // Si no es JSON válido (puede ser texto plano), devolverlo tal cual.
            return rawResponse;
        }
    }
}
