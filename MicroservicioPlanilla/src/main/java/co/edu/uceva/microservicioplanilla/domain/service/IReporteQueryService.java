package co.edu.uceva.microservicioplanilla.domain.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface IReporteQueryService {
    Map<String, Object> resumenPorPlanilla(Long planillaId);
    Map<String, Object> resumenJustificaciones();
    Map<String, Object> ausentismoPorRango(LocalDateTime inicio, LocalDateTime fin);
    Map<String, Object> trazabilidadEstudiante(String codigoEstudiante);

    Map<String, Object> estadisticasPorEncabezado(Long planillaId, String nombreEncabezado);
    List<Map<String, Object>> estadisticasCompletasPlanilla(Long planillaId);
    Map<String, Object> comparativaEncabezados(Long planillaId, List<String> nombresEncabezados);
}
