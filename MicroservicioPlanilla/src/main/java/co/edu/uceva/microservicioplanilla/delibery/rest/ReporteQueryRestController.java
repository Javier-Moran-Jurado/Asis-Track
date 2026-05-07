package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.domain.service.IReporteQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/planilla-service/reportes")
@RequiredArgsConstructor
public class ReporteQueryRestController {

    private final IReporteQueryService reporteQueryService;

    @GetMapping("/planilla/{planillaId}/resumen")
    public ResponseEntity<Map<String, Object>> resumenPorPlanilla(@PathVariable Long planillaId) {
        return ResponseEntity.ok(reporteQueryService.resumenPorPlanilla(planillaId));
    }

    @GetMapping("/justificaciones/resumen")
    public ResponseEntity<Map<String, Object>> resumenJustificaciones() {
        return ResponseEntity.ok(reporteQueryService.resumenJustificaciones());
    }

    @GetMapping("/ausentismo/rango")
    public ResponseEntity<Map<String, Object>> ausentismoPorRango(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fin) {
        return ResponseEntity.ok(reporteQueryService.ausentismoPorRango(inicio, fin));
    }

    @GetMapping("/estudiante/{codigoEstudiante}/trazabilidad")
    public ResponseEntity<Map<String, Object>> trazabilidadEstudiante(@PathVariable String codigoEstudiante) {
        return ResponseEntity.ok(reporteQueryService.trazabilidadEstudiante(codigoEstudiante));
    }

    @GetMapping("/planilla/{planillaId}/encabezado/{nombre}/estadisticas")
    public ResponseEntity<Map<String, Object>> estadisticasPorEncabezado(
            @PathVariable Long planillaId,
            @PathVariable String nombre) {
        return ResponseEntity.ok(reporteQueryService.estadisticasPorEncabezado(planillaId, nombre));
    }

    @GetMapping("/planilla/{planillaId}/estadisticas-completas")
    public ResponseEntity<List<Map<String, Object>>> estadisticasCompletasPlanilla(@PathVariable Long planillaId) {
        return ResponseEntity.ok(reporteQueryService.estadisticasCompletasPlanilla(planillaId));
    }

    @GetMapping("/planilla/{planillaId}/comparativa")
    public ResponseEntity<Map<String, Object>> comparativaEncabezados(
            @PathVariable Long planillaId,
            @RequestParam List<String> encabezados) {
        return ResponseEntity.ok(reporteQueryService.comparativaEncabezados(planillaId, encabezados));
    }
}
