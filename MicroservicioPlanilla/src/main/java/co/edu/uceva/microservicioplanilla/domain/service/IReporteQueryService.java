package co.edu.uceva.microservicioplanilla.domain.service;

import java.util.List;
import java.util.Map;

public interface IReporteQueryService {
    Map<String, Object> resumenJustificaciones();

    Map<String, Object> estadisticasPorCampo(Long planillaId, String nombreCampo);
    List<Map<String, Object>> estadisticasCompletasPlanilla(Long planillaId);
    Map<String, Object> comparativaCampos(Long planillaId, List<String> nombresCampos);
}
