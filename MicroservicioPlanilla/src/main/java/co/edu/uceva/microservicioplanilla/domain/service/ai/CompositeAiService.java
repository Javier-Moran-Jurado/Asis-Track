package co.edu.uceva.microservicioplanilla.domain.service.ai;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service("compositeAiService")
public class CompositeAiService {

    private final IAiModelService cloudService;
    private final IAiModelService huggingFaceService;
    private final IAiModelService ollamaService;
    private final IAiModelService groqService;
    private final DynamicAiConfigService configService;
    private final ITipoCampoRepository tipoCampoRepository;
    private final RestTemplate restTemplate = new RestTemplate();
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

    @Autowired
    public CompositeAiService(
            @Qualifier("cloudAiService") IAiModelService cloudService,
            @Qualifier("huggingFaceAiService") IAiModelService huggingFaceService,
            @Qualifier("ollamaAiService") IAiModelService ollamaService,
            @Qualifier("groqAiService") IAiModelService groqService,
            DynamicAiConfigService configService,
            ITipoCampoRepository tipoCampoRepository) {
        this.cloudService = cloudService;
        this.huggingFaceService = huggingFaceService;
        this.ollamaService = ollamaService;
        this.groqService = groqService;
        this.configService = configService;
        this.tipoCampoRepository = tipoCampoRepository;
    }

    private IAiModelService getPrimaryService() {
        String provider = configService.getActiveProvider();
        if (provider != null) {
            provider = provider.trim();
        }
        if ("hf".equalsIgnoreCase(provider)) return huggingFaceService;
        if ("cloud".equalsIgnoreCase(provider)) return cloudService;
        if ("groq".equalsIgnoreCase(provider)) return groqService;
        return ollamaService;
    }

    private IAiModelService getFallbackService() {
        String provider = configService.getActiveProvider();
        if (provider != null) {
            provider = provider.trim();
        }
        if ("ollama".equalsIgnoreCase(provider)) return cloudService;
        return ollamaService;
    }

    @Cacheable("tiposCampo")
    public String getTiposPermitidosFormateados() {
        return tipoCampoRepository.findAll().stream()
                .map(TipoCampo::getTipo)
                .collect(Collectors.joining(", "));
    }

    public String processBatch(List<Resource> images, String estructuraJson) {
        List<CompletableFuture<String>> futures = images.stream()
                .map(img -> CompletableFuture.supplyAsync(() -> processSingleImageWithFallback(img, estructuraJson)))
                .collect(Collectors.toList());

        return futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.joining("\n\n"));
    }

    public String generateCacheKey(Resource image) {
        if (image == null) return "null-image";
        try (InputStream is = image.getInputStream()) {
            return DigestUtils.md5DigestAsHex(is);
        } catch (IOException e) {
            return String.valueOf(image.hashCode());
        }
    }

    @Cacheable(value = "ocrImagesCache", key = "target.generateCacheKey(#image) + #estructuraJson.hashCode()")
    public String processSingleImageWithFallback(Resource image, String estructuraJson) {
        IAiModelService primaryService = getPrimaryService();
        IAiModelService fallbackService = getFallbackService();
        
        try {
            System.out.println("[*] Intentando OCR con modelo primario: " + primaryService.getProviderName());
            return primaryService.extractText(List.of(image), estructuraJson);
        } catch (Exception e) {
            System.err.println("[!] Error con el modelo primario (" + primaryService.getProviderName() + "): " + e.getMessage());
            System.err.println("[*] Iniciando fallback con modelo secundario: " + fallbackService.getProviderName());
            try {
                return fallbackService.extractText(List.of(image), estructuraJson);
            } catch (Exception fallbackEx) {
                System.err.println("[!] Error crítico en fallback (" + fallbackService.getProviderName() + "): " + fallbackEx.getMessage());
                return "[Error de OCR: Ambos modelos fallaron. " + fallbackEx.getMessage() + "]";
            }
        }
    }

    public String processStructureBatch(List<Resource> images) {
        List<CompletableFuture<String>> futures = images.stream()
                .map(img -> CompletableFuture.supplyAsync(() -> processSingleImageStructureWithFallback(img)))
                .collect(Collectors.toList());

        return futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.joining("\n\n"));
    }

    @Cacheable(value = "ocrStructureCache", key = "target.generateCacheKey(#image)")
    public String processSingleImageStructureWithFallback(Resource image) {
        IAiModelService primaryService = getPrimaryService();
        IAiModelService fallbackService = getFallbackService();
        String tiposPermitidos = getTiposPermitidosFormateados();
        
        try {
            System.out.println("[*] Intentando Extracción de Estructura con modelo primario: " + primaryService.getProviderName());
            return primaryService.extractStructure(List.of(image), tiposPermitidos);
        } catch (Exception e) {
            System.err.println("[!] Error con el modelo primario (" + primaryService.getProviderName() + "): " + e.getMessage());
            System.err.println("[*] Iniciando fallback de Estructura con modelo secundario: " + fallbackService.getProviderName());
            try {
                return fallbackService.extractStructure(List.of(image), tiposPermitidos);
            } catch (Exception fallbackEx) {
                System.err.println("[!] Error crítico en fallback de Estructura (" + fallbackService.getProviderName() + "): " + fallbackEx.getMessage());
                return "[Error de OCR: Ambos modelos fallaron al extraer la estructura. " + fallbackEx.getMessage() + "]";
            }
        }
    }

    public String processSingleImageStructureFromImageWithFallback(Resource image) {
        IAiModelService primaryService = getPrimaryService();
        IAiModelService fallbackService = getFallbackService();
        String tiposPermitidos = getTiposPermitidosFormateados();

        try {
            System.out.println("[*] Intentando Extracción de Estructura desde Imagen con modelo primario: " + primaryService.getProviderName());
            return primaryService.extractStructureFromImage(List.of(image), tiposPermitidos);
        } catch (Exception e) {
            System.err.println("[!] Error con el modelo primario (" + primaryService.getProviderName() + "): " + e.getMessage());
            System.err.println("[*] Iniciando fallback de Estructura desde Imagen con modelo secundario: " + fallbackService.getProviderName());
            try {
                return fallbackService.extractStructureFromImage(List.of(image), tiposPermitidos);
            } catch (Exception fallbackEx) {
                System.err.println("[!] Error crítico en fallback de Estructura desde Imagen (" + fallbackService.getProviderName() + "): " + fallbackEx.getMessage());
                return "[Error: Ambos modelos fallaron al extraer la estructura desde imagen. " + fallbackEx.getMessage() + "]";
            }
        }
    }

    public String generateFromText(String prompt) {
        String provider = configService.getActiveProvider();
        if (provider != null) provider = provider.trim();

        // Preferir Groq o Cloud para texto (formato OpenAI compatible)
        if ("groq".equalsIgnoreCase(provider)) {
            return callOpenAiCompatibleChat(configService.getGroqUrl(), configService.getGroqToken(), configService.getGroqModel(), prompt);
        }
        if ("cloud".equalsIgnoreCase(provider)) {
            return callOpenAiCompatibleChat(configService.getCloudBaseUrl(), configService.getCloudApiKey(), configService.getCloudModelName(), prompt);
        }
        // Fallback a Groq
        return callOpenAiCompatibleChat(configService.getGroqUrl(), configService.getGroqToken(), configService.getGroqModel(), prompt);
    }

    private String callOpenAiCompatibleChat(String baseUrl, String apiKey, String modelName, String prompt) {
        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Base URL no configurada para generación de texto.");
        }
        if (apiKey == null || apiKey.isEmpty()) {
            throw new IllegalStateException("API Key no configurada para generación de texto.");
        }

        try {
            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", prompt);

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", modelName);
            payload.put("messages", List.of(message));
            payload.put("temperature", 0.1);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);
            String endpoint = baseUrl.endsWith("/chat/completions") ? baseUrl : baseUrl + "/chat/completions";

            String responseJson = restTemplate.postForObject(endpoint, requestEntity, String.class);

            com.fasterxml.jackson.databind.JsonNode rootNode = objectMapper.readTree(responseJson);
            com.fasterxml.jackson.databind.JsonNode choices = rootNode.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                return choices.get(0).path("message").path("content").asText();
            }
            return "Error: No content in response.";
        } catch (Exception e) {
            throw new RuntimeException("Error en generación de texto: " + e.getMessage(), e);
        }
    }
}
