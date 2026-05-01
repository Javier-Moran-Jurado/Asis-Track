package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import co.edu.uceva.microservicioplanilla.utils.SpellCheckerUtil;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.content.Media;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;

import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Service("cloudAiService")
public class OpenAiServiceImpl implements IAiModelService {

    @Autowired(required = false)
    private OpenAiChatModel model;

    @Value("${app.ai.cloud.model:gpt-4o-mini}")
    private String modelName;

    @Override
    public String getProviderName() {
        return "Cloud API (OpenAI Compatible - " + modelName + ")";
    }

    @Override
    public String generateResponse(List<Resource> images) {
        if (model == null) {
            throw new IllegalStateException("OpenAI model is not configured.");
        }

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
                        .model(modelName)
                        .temperature(0.0)
                        .build();

                // 4. Llamar al modelo
                ChatResponse response = model.call(new Prompt(userMessage, options));

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
