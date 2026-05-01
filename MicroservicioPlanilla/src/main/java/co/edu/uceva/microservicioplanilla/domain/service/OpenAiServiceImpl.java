package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import co.edu.uceva.microservicioplanilla.utils.SpellCheckerUtil;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.content.Media;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;

import java.util.List;

@Service("cloudAiService")
@AllArgsConstructor
public class OpenAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;

    @Override
    public String getProviderName() {
        return "Cloud API (OpenAI Compatible - " + configService.getCloudModelName() + ")";
    }

    @Override
    public String generateResponse(List<Resource> images) {
        String baseUrl = configService.getCloudBaseUrl();
        String apiKey = configService.getCloudApiKey();
        
        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Cloud API Base URL is not configured.");
        }

        OpenAiApi api = OpenAiApi.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .build();
                
        OpenAiChatModel dynamicModel = OpenAiChatModel.builder()
                .openAiApi(api)
                .build();

        StringBuilder fullText = new StringBuilder();

        for (Resource image : images) {
            try {
                // 1. Preprocesar imagen
                Resource processedImg = ImagePreprocessor.preprocessImage(image);

                // 2. Crear mensaje
                UserMessage userMessage = UserMessage.builder()
                        .text("Text Recognition: Extrae todo el texto de la imagen y entrégalo en el formato JSON esperado.")
                        .media(List.of(new Media(MimeTypeUtils.IMAGE_JPEG, processedImg)))
                        .build();

                // 3. Configurar opciones del modelo
                OpenAiChatOptions options = OpenAiChatOptions.builder()
                        .model(configService.getCloudModelName())
                        .temperature(0.0)
                        .build();

                // 4. Llamar al modelo
                ChatResponse response = dynamicModel.call(new Prompt(userMessage, options));

                if (response != null && response.getResult() != null) {
                    String rawText = response.getResult().getOutput().getText();
                    // 5. Corrección ortográfica
                    String corrected = SpellCheckerUtil.correctText(rawText);
                    fullText.append(corrected).append("\n\n");
                }
            } catch (Exception e) {
                throw new RuntimeException("Error en Cloud API: " + e.getMessage(), e);
            }
        }
        return fullText.toString().trim();
    }
}
