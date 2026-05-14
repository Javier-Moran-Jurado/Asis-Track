package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.CampoRequest;

import java.util.List;

public interface ICampoService {
    List<Campo> findAll();
    Campo findById(Long id);
    Campo save(Campo campo);
    Campo save(CampoRequest request);
    Campo update(Campo campo);
    Campo update(Long id, CampoRequest request);
    void deleteById(Long id);
    List<Campo> findByPlanillaId(Long planillaId);
    boolean existsById(Long id);
    List<Campo> saveAll(List<CampoRequest> requests);
}
