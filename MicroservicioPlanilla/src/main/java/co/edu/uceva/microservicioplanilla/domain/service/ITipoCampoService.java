package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;

import java.util.List;

public interface ITipoCampoService {
    List<TipoCampo> findAll();
    TipoCampo findById(Long id);
    TipoCampo save(TipoCampo tipoCampo);
    TipoCampo update(TipoCampo tipoCampo);
    void deleteById(Long id);
}
