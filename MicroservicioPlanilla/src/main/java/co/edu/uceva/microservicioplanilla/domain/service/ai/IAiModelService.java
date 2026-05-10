package co.edu.uceva.microservicioplanilla.domain.service.ai;

import org.springframework.core.io.Resource;
import java.util.List;

public interface IAiModelService {
    String extractText(List<Resource> images, String estructuraJson);
    String extractStructure(List<Resource> images, String tiposPermitidos);
    String getProviderName();
}
