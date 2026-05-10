package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;

import java.util.List;

public interface IDatoService {
    List<Dato> findAll();
    Dato findById(Long id);
    Dato save(Dato dato);
    Dato update(Dato dato);
    void deleteById(Long id);
    List<Dato> findByPlanillaId(Long planillaId);
    List<Dato> findByPlanillaIdAndIndice(Long planillaId, Integer indice);
    List<Dato> findByCampoId(Long campoId);
}
