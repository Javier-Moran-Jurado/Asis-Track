package co.edu.uceva.microservicioplanilla.domain.service;

import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

@Service
@Data
public class DynamicAiConfigService {

    @Value("${app.ai.primary:hf}")
    private String activeProvider;

    // Cloud / OpenAI Compatible
    @Value("${spring.ai.openai.base-url:https://api.openai.com}")
    private String cloudBaseUrl;
    
    @Value("${spring.ai.openai.api-key:}")
    private String cloudApiKey;
    
    @Value("${app.ai.cloud.model:gpt-4o-mini}")
    private String cloudModelName;

    // Hugging Face / Raw APIs
    @Value("${app.ai.hf.url:https://router.huggingface.co/zai-org/api/paas/v4/layout_parsing}")
    private String hfUrl;
    
    @Value("${app.ai.hf.token:}")
    private String hfToken;
    
    // Ollama
    @Value("${spring.ai.ollama.base-url:http://localhost:11434}")
    private String ollamaBaseUrl;

    @Value("${app.ai.ollama.model:ocr-masivo}")
    private String ollamaModel;

    // Groq
    @Value("${app.ai.groq.url:https://api.groq.com/openai/v1}")
    private String groqUrl;
    
    @Value("${app.ai.groq.token:}")
    private String groqToken;
    
    @Value("${app.ai.groq.model:meta-llama/llama-4-scout-17b-16e-instruct}")
    private String groqModel;

    public void updateConfig(String provider, String baseUrl, String token, String modelName) {
        if (provider != null && !provider.isEmpty()) {
            this.activeProvider = provider;
        }
        
        if ("cloud".equalsIgnoreCase(provider)) {
            if (baseUrl != null && !baseUrl.isEmpty()) this.cloudBaseUrl = baseUrl;
            if (token != null && !token.isEmpty()) this.cloudApiKey = token;
            if (modelName != null && !modelName.isEmpty()) this.cloudModelName = modelName;
        } else if ("hf".equalsIgnoreCase(provider)) {
            if (baseUrl != null && !baseUrl.isEmpty()) this.hfUrl = baseUrl;
            if (token != null && !token.isEmpty()) this.hfToken = token;
        } else if ("ollama".equalsIgnoreCase(provider)) {
            if (baseUrl != null && !baseUrl.isEmpty()) this.ollamaBaseUrl = baseUrl;
            if (modelName != null && !modelName.isEmpty()) this.ollamaModel = modelName;
        } else if ("groq".equalsIgnoreCase(provider)) {
            if (baseUrl != null && !baseUrl.isEmpty()) this.groqUrl = baseUrl;
            if (token != null && !token.isEmpty()) this.groqToken = token;
            if (modelName != null && !modelName.isEmpty()) this.groqModel = modelName;
        }
    }
}
