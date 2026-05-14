package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.EstadoJustificacion;
import co.edu.uceva.microservicioplanilla.domain.model.Justificacion;

import java.util.List;

public interface IJustificacionService {
    Justificacion solicitarJustificacion(Long eventoId, Long codigoEstudiante, String motivo, String documentoUrl);
    Justificacion aprobarJustificacion(Long id, Long codigoDecano, String observaciones);
    Justificacion rechazarJustificacion(Long id, Long codigoDecano, String observaciones);
    Justificacion findById(Long id);
    List<Justificacion> findByCodigoEstudiante(Long codigoEstudiante);
    List<Justificacion> findByEventoId(Long eventoId);
    List<Justificacion> findByEstado(EstadoJustificacion estado);
    List<Justificacion> findAll();
    Justificacion update(Justificacion justificacion);
    void deleteById(Long id);
}
