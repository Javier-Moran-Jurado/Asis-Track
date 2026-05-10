package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.*;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IJustificacionRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReporteQueryServiceImpl implements IReporteQueryService {

    private final IPlanillaRepository planillaRepository;
    private final IJustificacionRepository justificacionRepository;
    private final ICampoRepository campoRepository;
    private final IDatoRepository datoRepository;

    @Override
    public Map<String, Object> resumenJustificaciones() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("pendientes", justificacionRepository.countByEstado(EstadoJustificacion.PENDIENTE));
        response.put("aprobadas", justificacionRepository.countByEstado(EstadoJustificacion.APROBADO));
        response.put("rechazadas", justificacionRepository.countByEstado(EstadoJustificacion.RECHAZADO));
        response.put("total", justificacionRepository.count());
        return response;
    }

    @Override
    public Map<String, Object> estadisticasPorCampo(Long planillaId, String nombreCampo) {
        Map<String, Object> response = new LinkedHashMap<>();

        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            response.put("error", "Planilla no encontrada");
            return response;
        }

        // Buscar el campo por nombre dentro de la planilla
        Campo campo = campoRepository.findByPlanillaIdAndNombreCampo(planillaId, nombreCampo);
        if (campo == null) {
            response.put("error", "Campo no encontrado: " + nombreCampo);
            return response;
        }

        List<Dato> datos = datoRepository.findByCampoId(campo.getId());

        response.put("planillaId", planillaId);
        response.put("campo", nombreCampo);
        response.put("tipoCampo", campo.getTipoCampo().getTipo());
        response.put("totalRegistros", datos.size());
        response.put("estadisticas", calcularEstadisticas(datos, campo.getTipoCampo().getTipo()));

        return response;
    }

    @Override
    public List<Map<String, Object>> estadisticasCompletasPlanilla(Long planillaId) {
        List<Map<String, Object>> resultados = new ArrayList<>();

        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            return resultados;
        }

        List<Campo> campos = campoRepository.findByPlanillaId(planillaId);

        for (Campo campo : campos) {
            Map<String, Object> stats = new LinkedHashMap<>();
            stats.put("campo", campo.getNombreCampo());
            stats.put("tipoCampo", campo.getTipoCampo().getTipo());

            List<Dato> datos = datoRepository.findByCampoId(campo.getId());
            stats.put("totalRegistros", datos.size());
            stats.put("estadisticas", calcularEstadisticas(datos, campo.getTipoCampo().getTipo()));

            resultados.add(stats);
        }

        return resultados;
    }

    @Override
    public Map<String, Object> comparativaCampos(Long planillaId, List<String> nombresCampos) {
        Map<String, Object> response = new LinkedHashMap<>();
        List<Map<String, Object>> resultados = new ArrayList<>();

        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            response.put("error", "Planilla no encontrada");
            return response;
        }

        for (String nombre : nombresCampos) {
            Campo campo = campoRepository.findByPlanillaIdAndNombreCampo(planillaId, nombre);
            if (campo != null) {
                List<Dato> datos = datoRepository.findByCampoId(campo.getId());
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("campo", nombre);
                item.put("tipoCampo", campo.getTipoCampo().getTipo());
                item.put("estadisticas", calcularEstadisticas(datos, campo.getTipoCampo().getTipo()));
                resultados.add(item);
            }
        }

        response.put("planillaId", planillaId);
        response.put("comparativa", resultados);
        return response;
    }

    private Map<String, Object> calcularEstadisticas(List<Dato> datos, String tipoCampo) {
        Map<String, Object> stats = new LinkedHashMap<>();

        List<String> valores = datos.stream()
                .map(Dato::getInformacion)
                .filter(v -> v != null && !v.isEmpty())
                .collect(Collectors.toList());

        stats.put("conRespuestas", valores.size());
        stats.put("sinRespuestas", datos.size() - valores.size());

        switch (tipoCampo) {
            case "combo":
            case "radio":
            case "checkbox":
            case "multivaluecheckbox":
                Map<String, Long> dist = valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting()));
                stats.put("distribucion", dist);
                break;
            case "numeric":
                if (!valores.isEmpty()) {
                    DoubleSummaryStatistics summary = valores.stream()
                            .mapToDouble(v -> {
                                try { return Double.parseDouble(v); } catch (Exception e) { return 0.0; }
                            })
                            .summaryStatistics();
                    stats.put("min", summary.getMin());
                    stats.put("max", summary.getMax());
                    stats.put("promedio", summary.getAverage());
                    stats.put("suma", summary.getSum());
                    stats.put("count", summary.getCount());
                }
                break;
            case "text":
            case "e-mail":
                stats.put("valoresUnicos", valores.stream().distinct().count());
                stats.put("valorMasComun", valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting()))
                        .entrySet().stream()
                        .max(Comparator.comparingLong(Map.Entry::getValue))
                        .map(Map.Entry::getKey)
                        .orElse(null));
                break;
            case "date":
                stats.put("totalFechas", valores.size());
                stats.put("valoresUnicos", valores.stream().distinct().count());
                break;
            default:
                stats.put("totalRegistrado", valores.size());
        }

        return stats;
    }
}
