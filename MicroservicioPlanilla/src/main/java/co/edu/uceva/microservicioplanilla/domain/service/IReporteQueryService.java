package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EstadisticasCampoResponse;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EstadisticasEventoResponse;

import java.util.List;
import java.util.Map;

public interface IReporteQueryService {
    Map<String, Object> resumenJustificaciones();

    EstadisticasEventoResponse estadisticasCompletasEvento(Long eventoId, Integer bins);
    EstadisticasCampoResponse estadisticasPorCampoEvento(Long eventoId, String nombreCampo, Integer bins);
    EstadisticasEventoResponse comparativaCamposEvento(Long eventoId, List<String> nombresCampos, Integer bins);
}
