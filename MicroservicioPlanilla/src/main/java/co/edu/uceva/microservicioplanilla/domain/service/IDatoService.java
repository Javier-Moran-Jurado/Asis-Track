package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoRequest;

import java.util.List;

public interface IDatoService {
    List<Dato> findAll();
    Dato findById(Long id);
    Dato save(DatoRequest request);
    Dato update(Long id, DatoRequest request);
    void deleteById(Long id);
    List<Dato> findByPlanillaId(Long planillaId);
    List<Dato> findByCampoId(Long campoId);
    List<Dato> saveAll(List<DatoRequest> requests);
}
