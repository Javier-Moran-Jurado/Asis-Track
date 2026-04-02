package co.edu.uceva.microservicioplanilla.domain.service;

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
import java.util.stream.Collectors;

@NoArgsConstructor
@AllArgsConstructor
@Service
public class OllamaAiService {
    @Autowired
    private OllamaChatModel model;

    public String generateResponse(List<Resource> images){
        OllamaChatOptions options = new OllamaChatOptions();
        options.setModel("ocr-masivo");

        UserMessage userMessage = UserMessage.builder()
                .text("Text Recognition:")
                .media(images.stream()
                        .map(base64 -> new Media(MimeTypeUtils.IMAGE_JPEG, base64))
                        .collect(Collectors.toList()))
                .build();
        ChatResponse response = model.call(new Prompt(userMessage, options));
        if (response != null){
            return response.getResult().getOutput().getText();
        }
        return "Error: No hubo respuesta";
    }
}
