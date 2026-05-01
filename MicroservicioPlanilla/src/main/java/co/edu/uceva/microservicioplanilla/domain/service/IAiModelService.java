package co.edu.uceva.microservicioplanilla.domain.service;

import org.springframework.core.io.Resource;
import java.util.List;

public interface IAiModelService {
    String generateResponse(List<Resource> images);
    String getProviderName();
}
