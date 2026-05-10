package co.edu.uceva.microservicioplanilla.domain.service.ai;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
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
}
