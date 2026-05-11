package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;

import java.util.List;

public interface IOrigenService {
    List<Origen> findAll();
    Origen findById(Long id);
    Origen save(Origen origen);
    Origen update(Origen origen);
    void deleteById(Long id);
}
