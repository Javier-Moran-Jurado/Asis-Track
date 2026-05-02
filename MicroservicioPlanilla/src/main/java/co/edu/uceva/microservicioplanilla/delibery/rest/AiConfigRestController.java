package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.delibery.rest.dto.AiConfigDto;
import co.edu.uceva.microservicioplanilla.domain.service.DynamicAiConfigService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/planilla-service/ai-config")
public class AiConfigRestController {

    private final DynamicAiConfigService configService;

    public AiConfigRestController(DynamicAiConfigService configService) {
        this.configService = configService;
    }

    @PreAuthorize("isAuthenticated() and hasRole('Administrador')")
    @GetMapping
    public AiConfigDto getConfig() {
        AiConfigDto dto = new AiConfigDto();
        dto.setActiveProvider(configService.getActiveProvider());
        dto.setCloudBaseUrl(configService.getCloudBaseUrl());
        // No devolver el token completo por seguridad, solo mostrar si está configurado
        dto.setCloudApiKey(configService.getCloudApiKey() != null && !configService.getCloudApiKey().isEmpty() ? "********" : "");
        dto.setCloudModelName(configService.getCloudModelName());
        dto.setHfUrl(configService.getHfUrl());
        dto.setHfToken(configService.getHfToken() != null && !configService.getHfToken().isEmpty() ? "********" : "");
        dto.setOllamaBaseUrl(configService.getOllamaBaseUrl());
        dto.setOllamaModel(configService.getOllamaModel());
        dto.setGroqUrl(configService.getGroqUrl());
        dto.setGroqToken(configService.getGroqToken() != null && !configService.getGroqToken().isEmpty() ? "********" : "");
        dto.setGroqModel(configService.getGroqModel());
        return dto;
    }

    @PreAuthorize("isAuthenticated() and hasRole('Administrador')")
    @PutMapping
    public String updateConfig(@RequestBody AiConfigDto dto) {
        // Enviar solo los campos que no sean nulos y que no sean la máscara de asteriscos
        String apiKey = dto.getCloudApiKey() != null && !dto.getCloudApiKey().equals("********") ? dto.getCloudApiKey() : null;
        String hfToken = dto.getHfToken() != null && !dto.getHfToken().equals("********") ? dto.getHfToken() : null;
        String groqToken = dto.getGroqToken() != null && !dto.getGroqToken().equals("********") ? dto.getGroqToken() : null;

        String baseUrlToUpdate = null;
        String tokenToUpdate = null;
        String modelToUpdate = null;

        if ("cloud".equalsIgnoreCase(dto.getActiveProvider())) {
            baseUrlToUpdate = dto.getCloudBaseUrl();
            tokenToUpdate = apiKey;
            modelToUpdate = dto.getCloudModelName();
        } else if ("hf".equalsIgnoreCase(dto.getActiveProvider())) {
            baseUrlToUpdate = dto.getHfUrl();
            tokenToUpdate = hfToken;
        } else if ("ollama".equalsIgnoreCase(dto.getActiveProvider())) {
            baseUrlToUpdate = dto.getOllamaBaseUrl();
            modelToUpdate = dto.getOllamaModel();
        } else if ("groq".equalsIgnoreCase(dto.getActiveProvider())) {
            baseUrlToUpdate = dto.getGroqUrl();
            tokenToUpdate = groqToken;
            modelToUpdate = dto.getGroqModel();
        }

        configService.updateConfig(
                dto.getActiveProvider(),
                baseUrlToUpdate,
                tokenToUpdate,
                modelToUpdate
        );

        return "Configuración de IA actualizada correctamente. Proveedor activo: " + configService.getActiveProvider();
    }
}
