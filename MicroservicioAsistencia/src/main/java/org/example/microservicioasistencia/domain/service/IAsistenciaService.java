package org.example.microservicioasistencia.domain.service;

import org.example.microservicioasistencia.domain.model.Asistencia;
import java.time.LocalDateTime;
import java.util.List;

public interface IAsistenciaService {
    Asistencia registrarEntrada(String codigoEstudiante, Long planillaId, String geolocalizacion, String datosAdicionales);
    Asistencia registrarSalida(String codigoEstudiante, Long planillaId, String geolocalizacion, String datosAdicionales);
    Asistencia justificarAusencia(String codigoEstudiante, Long planillaId, String datosAdicionales);
    Asistencia findById(Long id);
    List<Asistencia> findByCodigoEstudiante(String codigoEstudiante);
    List<Asistencia> findByPlanillaId(Long planillaId);
    List<Asistencia> findPresentesByPlanilla(Long planillaId);
    List<Asistencia> findByFechaHoraRegistroBetween(LocalDateTime inicio, LocalDateTime fin);
    Asistencia update(Asistencia asistencia);
    void deleteById(Long id);
    Asistencia actualizarEstado(Long id, String nuevoEstado);  // ← NUEVO MÉTODO
}