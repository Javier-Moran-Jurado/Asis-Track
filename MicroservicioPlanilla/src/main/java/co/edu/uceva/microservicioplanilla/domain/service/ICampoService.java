package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;

import java.util.List;

public interface ICampoService {
    List<Campo> findAll();
    Campo findById(Long id);
    Campo save(Campo campo);
    Campo update(Campo campo);
    void deleteById(Long id);
    List<Campo> findByPlanillaId(Long planillaId);
}
