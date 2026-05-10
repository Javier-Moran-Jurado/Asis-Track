package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.FilaRequest;
import co.edu.uceva.microservicioplanilla.domain.model.Fila;

import java.util.List;

public interface IFilaService {
    List<Fila> findAll();
    Fila findById(Long id);
    List<Fila> findByPlanillaId(Long planillaId);
    List<Fila> findByCodigoUsuario(Long codigoUsuario);
    Fila findByPlanillaIdAndIndice(Long planillaId, Integer indice);
    Fila create(FilaRequest request);
    List<Fila> createBatch(List<FilaRequest> requests);
    Fila updateFull(Long id, FilaRequest request);
    Fila patch(Long id, FilaRequest request);
    void deleteById(Long id);
}
