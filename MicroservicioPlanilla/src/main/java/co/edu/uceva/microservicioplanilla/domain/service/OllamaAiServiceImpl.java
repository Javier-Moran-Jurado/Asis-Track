package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import co.edu.uceva.microservicioplanilla.utils.SpellCheckerUtil;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.content.Media;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.ollama.api.OllamaChatOptions;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;

import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Service("ollamaAiService")
public class OllamaAiServiceImpl implements IAiModelService {

    @Autowired
    private OllamaChatModel model;

    @Override
    public String getProviderName() {
        return "Ollama";
    }

    @Override

    public String generateResponse(List<Resource> images) {
        StringBuilder fullText = new StringBuilder();

        for (Resource image : images) {
            try {
                // 1. Preprocesar imagen
                Resource processedImg = ImagePreprocessor.preprocessImage(image);

                // 2. Crear mensaje con una sola imagen
                UserMessage userMessage = UserMessage.builder()
                        .text("Text Recognition:")
                        .media(List.of(new Media(MimeTypeUtils.IMAGE_JPEG, processedImg)))
                        .build();

                // 3. Configurar opciones del modelo (usa el modelo creado por tu compañero)
                OllamaChatOptions options = OllamaChatOptions.builder()
                        .model("ocr-masivo")
                        .build();

                // 4. Llamar al modelo
                ChatResponse response = model.call(new Prompt(userMessage, options));

                if (response != null) {
                    String rawText = response.getResult().getOutput().getText();
                    // 5. Corrección ortográfica
                    String corrected = SpellCheckerUtil.correctText(rawText);
                    fullText.append(corrected).append("\n\n");
                }
            } catch (Exception e) {
                fullText.append("[Error procesando imagen: ").append(e.getMessage()).append("]\n\n");
            }
        }
        return fullText.toString().trim();
    }
}