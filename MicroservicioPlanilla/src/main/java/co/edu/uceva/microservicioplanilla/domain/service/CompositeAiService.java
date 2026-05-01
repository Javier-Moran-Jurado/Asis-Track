package co.edu.uceva.microservicioplanilla.domain.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
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

    private final IAiModelService primaryService;
    private final IAiModelService fallbackService;

    @Autowired
    public CompositeAiService(
            @Qualifier("cloudAiService") IAiModelService cloudService,
            @Qualifier("ollamaAiService") IAiModelService ollamaService,
            @Value("${app.ai.primary:cloud}") String primaryProvider) {
        
        if ("cloud".equalsIgnoreCase(primaryProvider)) {
            this.primaryService = cloudService;
            this.fallbackService = ollamaService;
        } else {
            this.primaryService = ollamaService;
            this.fallbackService = cloudService;
        }
    }

    /**
     * Procesa una lista de imágenes de forma paralela (lotes de planillas)
     * reduciendo el tiempo total de procesamiento.
     */
    public String processBatch(List<Resource> images) {
        List<CompletableFuture<String>> futures = images.stream()
                .map(img -> CompletableFuture.supplyAsync(() -> processSingleImageWithFallback(img)))
                .collect(Collectors.toList());

        return futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.joining("\n\n"));
    }

    /**
     * Genera un hash MD5 del recurso para usarlo como clave de caché.
     */
    private String generateCacheKey(Resource image) {
        try (InputStream is = image.getInputStream()) {
            return DigestUtils.md5DigestAsHex(is);
        } catch (IOException e) {
            return String.valueOf(image.hashCode()); // Fallback if cannot read
        }
    }

    /**
     * Procesa una sola imagen, intentando usar el caché primero.
     * La anotación @Cacheable usa redis/in-memory para no reprocesar imágenes idénticas.
     */
    @Cacheable(value = "ocrImagesCache", key = "target.generateCacheKey(#image)")
    public String processSingleImageWithFallback(Resource image) {
        try {
            System.out.println("[*] Intentando OCR con modelo primario: " + primaryService.getProviderName());
            return primaryService.generateResponse(List.of(image));
        } catch (Exception e) {
            System.err.println("[!] Error con el modelo primario (" + primaryService.getProviderName() + "): " + e.getMessage());
            System.err.println("[*] Iniciando fallback con modelo secundario: " + fallbackService.getProviderName());
            
            try {
                return fallbackService.generateResponse(List.of(image));
            } catch (Exception fallbackEx) {
                System.err.println("[!] Error crítico en fallback (" + fallbackService.getProviderName() + "): " + fallbackEx.getMessage());
                return "[Error de OCR: Ambos modelos fallaron. " + fallbackEx.getMessage() + "]";
            }
        }
    }
}
