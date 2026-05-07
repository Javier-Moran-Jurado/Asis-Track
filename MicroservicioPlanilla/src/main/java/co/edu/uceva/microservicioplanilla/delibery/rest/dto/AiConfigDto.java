package co.edu.uceva.microservicioplanilla.delibery.rest.dto;

import lombok.Data;

@Data
public class AiConfigDto {
    private String activeProvider; // "cloud", "hf", "ollama"
    private String cloudBaseUrl;
    private String cloudApiKey;
    private String cloudModelName;
    private String hfUrl;
    private String hfToken;
    private String ollamaBaseUrl;
    private String ollamaModel;
    private String groqUrl;
    private String groqToken;
    private String groqModel;
}
