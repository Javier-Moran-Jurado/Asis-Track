package org.example.microserviciojustificacion.domain.service;

import org.example.microserviciojustificacion.domain.model.Justificacion;
import java.util.List;

public interface IJustificacionService {

    Justificacion solicitarJustificacion(Long registroId, String usuarioCodigo, String motivo, String documentoUrl);

    Justificacion aprobarJustificacion(Long id, String revisadoPor, String observaciones);

    Justificacion rechazarJustificacion(Long id, String revisadoPor, String observaciones);

    Justificacion findById(Long id);

    List<Justificacion> findByUsuarioCodigo(String usuarioCodigo);

    List<Justificacion> findByRegistroId(Long registroId);

    List<Justificacion> findByEstado(String estado);

    List<Justificacion> findAll();

    Justificacion update(Justificacion justificacion);

    void deleteById(Long id);
}
