package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;

import java.util.List;

public interface ILugarService {
    List<Lugar> findAll();
    Lugar findById(Long id);
    Lugar save(Lugar lugar);
    Lugar update(Lugar lugar);
    void deleteById(Long id);
}
