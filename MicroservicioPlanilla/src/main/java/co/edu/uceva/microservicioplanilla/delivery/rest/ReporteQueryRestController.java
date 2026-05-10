package co.edu.uceva.microservicioplanilla.delivery.rest;

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

    @GetMapping("/planilla/{planillaId}/campo/{nombre}/estadisticas")
    public ResponseEntity<Map<String, Object>> estadisticasPorCampo(
            @PathVariable Long planillaId,
            @PathVariable String nombre) {
        return ResponseEntity.ok(reporteQueryService.estadisticasPorCampo(planillaId, nombre));
    }

    @GetMapping("/planilla/{planillaId}/estadisticas-completas")
    public ResponseEntity<List<Map<String, Object>>> estadisticasCompletasPlanilla(@PathVariable Long planillaId) {
        return ResponseEntity.ok(reporteQueryService.estadisticasCompletasPlanilla(planillaId));
    }

    @GetMapping("/planilla/{planillaId}/comparativa")
    public ResponseEntity<Map<String, Object>> comparativaCampos(
            @PathVariable Long planillaId,
            @RequestParam List<String> campos) {
        return ResponseEntity.ok(reporteQueryService.comparativaCampos(planillaId, campos));
    }
}
