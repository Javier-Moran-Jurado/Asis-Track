package co.edu.uceva.microservicioreporte.domain.service;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;

import java.util.List;

public interface IReporteService {

    List<Reporte> findAll();

    Reporte findById(Long id);

    Reporte save(Reporte reporte);

    Reporte update(Reporte reporte);

    void deleteById(Long id);
}