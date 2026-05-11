package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EstadisticasCampoResponse;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EstadisticasEventoResponse;
import co.edu.uceva.microservicioplanilla.domain.service.IReporteQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/planilla-service/reportes")
@RequiredArgsConstructor
public class ReporteQueryRestController {

    private final IReporteQueryService reporteQueryService;

    @GetMapping("/justificaciones/resumen")
    public ResponseEntity<Map<String, Object>> resumenJustificaciones() {
        return ResponseEntity.ok(reporteQueryService.resumenJustificaciones());
    }

    @GetMapping("/evento/{eventoId}/campo/{nombreCampo}/estadisticas")
    public ResponseEntity<EstadisticasCampoResponse> estadisticasPorCampo(
            @PathVariable Long eventoId,
            @PathVariable String nombreCampo,
            @RequestParam(required = false) Integer bins) {
        return ResponseEntity.ok(reporteQueryService.estadisticasPorCampoEvento(eventoId, nombreCampo, bins));
    }

    @GetMapping("/evento/{eventoId}/estadisticas-completas")
    public ResponseEntity<EstadisticasEventoResponse> estadisticasCompletasEvento(
            @PathVariable Long eventoId,
            @RequestParam(required = false) Integer bins) {
        return ResponseEntity.ok(reporteQueryService.estadisticasCompletasEvento(eventoId, bins));
    }

    @GetMapping("/evento/{eventoId}/comparativa")
    public ResponseEntity<EstadisticasEventoResponse> comparativaCampos(
            @PathVariable Long eventoId,
            @RequestParam List<String> campos,
            @RequestParam(required = false) Integer bins) {
        return ResponseEntity.ok(reporteQueryService.comparativaCamposEvento(eventoId, campos, bins));
    }
}
