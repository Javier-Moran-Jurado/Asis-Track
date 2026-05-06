package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Asistencia;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.repository.IAsistenciaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IJustificacionRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.DoubleSummaryStatistics;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReporteQueryServiceImpl implements IReporteQueryService {

    private final IPlanillaRepository planillaRepository;
    private final IAsistenciaRepository asistenciaRepository;
    private final IJustificacionRepository justificacionRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public Map<String, Object> resumenPorPlanilla(Long planillaId) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("planillaId", planillaId);
        response.put("planillaExiste", planillaRepository.existsById(planillaId));
        response.put("totalRegistros", asistenciaRepository.countByPlanillaId(planillaId));
        response.put("presentes", asistenciaRepository.countByPlanillaIdAndEstado(planillaId, "PRESENTE"));
        response.put("salidas", asistenciaRepository.countByPlanillaIdAndEstado(planillaId, "SALIDA"));
        response.put("justificados", asistenciaRepository.countByPlanillaIdAndEstado(planillaId, "JUSTIFICADO"));
        response.put("ausentes", asistenciaRepository.countByPlanillaIdAndEstado(planillaId, "AUSENTE"));
        return response;
    }

    @Override
    public Map<String, Object> resumenJustificaciones() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("pendientes", justificacionRepository.countByEstado("PENDIENTE"));
        response.put("aprobadas", justificacionRepository.countByEstado("APROBADO"));
        response.put("rechazadas", justificacionRepository.countByEstado("RECHAZADO"));
        response.put("total", justificacionRepository.count());
        return response;
    }

    @Override
    public Map<String, Object> ausentismoPorRango(LocalDateTime inicio, LocalDateTime fin) {
        long total = asistenciaRepository.findByFechaHoraRegistroBetween(inicio, fin).size();
        long ausentes = asistenciaRepository.findByFechaHoraRegistroBetween(inicio, fin)
                .stream()
                .filter(a -> "AUSENTE".equalsIgnoreCase(a.getEstado()))
                .count();

        double porcentajeAusentismo = total == 0 ? 0.0 : (ausentes * 100.0) / total;

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("inicio", inicio);
        response.put("fin", fin);
        response.put("totalRegistros", total);
        response.put("ausentes", ausentes);
        response.put("porcentajeAusentismo", porcentajeAusentismo);
        return response;
    }

    @Override
    public Map<String, Object> trazabilidadEstudiante(String codigoEstudiante) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("codigoEstudiante", codigoEstudiante);
        response.put("totalRegistrosAsistencia", asistenciaRepository.countByCodigoEstudiante(codigoEstudiante));
        response.put("justificacionesPendientes", justificacionRepository.findByUsuarioCodigoAndEstado(codigoEstudiante, "PENDIENTE").size());
        response.put("justificacionesAprobadas", justificacionRepository.findByUsuarioCodigoAndEstado(codigoEstudiante, "APROBADO").size());
        response.put("justificacionesRechazadas", justificacionRepository.findByUsuarioCodigoAndEstado(codigoEstudiante, "RECHAZADO").size());
        return response;
    }

    @Override
    public Map<String, Object> estadisticasPorEncabezado(Long planillaId, String nombreEncabezado) {
        Map<String, Object> response = new LinkedHashMap<>();
        
        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            response.put("error", "Planilla no encontrada");
            return response;
        }

        List<Encabezado> encabezados = parsearEncabezados(planilla.getEstructuraMetadata());
        Encabezado encabezado = encabezados.stream()
                .filter(e -> e.getNombre().equalsIgnoreCase(nombreEncabezado))
                .findFirst()
                .orElse(null);

        if (encabezado == null) {
            response.put("error", "Encabezado no encontrado: " + nombreEncabezado);
            return response;
        }

        List<Asistencia> asistencias = asistenciaRepository.findByPlanillaId(planillaId);
        List<Map<String, String>> datos = extraerDatosAdicionales(asistencias, nombreEncabezado);

        response.put("planillaId", planillaId);
        response.put("encabezado", nombreEncabezado);
        response.put("tipoCampo", encabezado.getTipoCampo());
        response.put("totalRegistros", datos.size());
        response.put("datos", calcularEstadisticas(datos, encabezado));

        return response;
    }

    @Override
    public List<Map<String, Object>> estadisticasCompletasPlanilla(Long planillaId) {
        List<Map<String, Object>> resultados = new ArrayList<>();

        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            return resultados;
        }

        List<Encabezado> encabezados = parsearEncabezados(planilla.getEstructuraMetadata());
        List<Asistencia> asistencias = asistenciaRepository.findByPlanillaId(planillaId);

        for (Encabezado encabezado : encabezados) {
            Map<String, Object> stats = new LinkedHashMap<>();
            stats.put("encabezado", encabezado.getNombre());
            stats.put("tipoCampo", encabezado.getTipoCampo());
            stats.put("opciones", encabezado.getOpciones());

            List<Map<String, String>> datos = extraerDatosAdicionales(asistencias, encabezado.getNombre());
            stats.put("totalRegistros", datos.size());
            stats.put("estadisticas", calcularEstadisticas(datos, encabezado));

            resultados.add(stats);
        }

        return resultados;
    }

    @Override
    public Map<String, Object> comparativaEncabezados(Long planillaId, List<String> nombresEncabezados) {
        Map<String, Object> response = new LinkedHashMap<>();
        List<Map<String, Object>> resultados = new ArrayList<>();

        Planilla planilla = planillaRepository.findById(planillaId).orElse(null);
        if (planilla == null) {
            response.put("error", "Planilla no encontrada");
            return response;
        }

        List<Encabezado> encabezados = parsearEncabezados(planilla.getEstructuraMetadata());
        List<Asistencia> asistencias = asistenciaRepository.findByPlanillaId(planillaId);

        for (String nombre : nombresEncabezados) {
            Encabezado encabezado = encabezados.stream()
                    .filter(e -> e.getNombre().equalsIgnoreCase(nombre))
                    .findFirst()
                    .orElse(null);

            if (encabezado != null) {
                List<Map<String, String>> datos = extraerDatosAdicionales(asistencias, nombre);
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("encabezado", nombre);
                item.put("tipoCampo", encabezado.getTipoCampo());
                item.put("estadisticas", calcularEstadisticas(datos, encabezado));
                resultados.add(item);
            }
        }

        response.put("planillaId", planillaId);
        response.put("comparativa", resultados);
        return response;
    }

    private List<Encabezado> parsearEncabezados(String estructuraMetadata) {
        List<Encabezado> resultado = new ArrayList<>();
        try {
            Map<String, Object> parsed = objectMapper.readValue(estructuraMetadata, new TypeReference<>() {});
            List<Map<String, Object>> encabezadosList = (List<Map<String, Object>>) parsed.get("encabezados");
            if (encabezadosList != null) {
                for (Map<String, Object> e : encabezadosList) {
                    Encabezado enc = new Encabezado();
                    enc.setNombre((String) e.get("nombre"));
                    enc.setTipoCampo((String) e.get("tipo_campo"));
                    List<String> opts = (List<String>) e.get("opciones");
                    enc.setOpciones(opts != null ? opts : new ArrayList<>());
                    resultado.add(enc);
                }
            }
        } catch (Exception e) {
            // estructura inválida
        }
        return resultado;
    }

    private List<Map<String, String>> extraerDatosAdicionales(List<Asistencia> asistencias, String nombreEncabezado) {
        List<Map<String, String>> resultados = new ArrayList<>();
        for (Asistencia a : asistencias) {
            if (a.getDatosAdicionales() != null && !a.getDatosAdicionales().isEmpty()) {
                try {
                    Map<String, Object> datos = objectMapper.readValue(a.getDatosAdicionales(), new TypeReference<>() {});
                    Map<String, String> item = new LinkedHashMap<>();
                    item.put("codigoEstudiante", a.getCodigoEstudiante());
                    Object valor = datos.get(nombreEncabezado);
                    item.put("valor", valor != null ? valor.toString() : null);
                    resultados.add(item);
                } catch (Exception e) {
                    // datos inválidos
                }
            }
        }
        return resultados;
    }

    private Map<String, Object> calcularEstadisticas(List<Map<String, String>> datos, Encabezado encabezado) {
        Map<String, Object> stats = new LinkedHashMap<>();
        String tipoCampo = encabezado.getTipoCampo();

        List<String> valores = datos.stream()
                .map(d -> d.get("valor"))
                .filter(v -> v != null && !v.isEmpty())
                .collect(Collectors.toList());

        stats.put("conRespuestas", valores.size());
        stats.put("sinRespuestas", datos.size() - valores.size());

        switch (tipoCampo) {
            case "desplegable":
            case "radio":
            case "checkbox":
                Map<String, Long> dist = valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting()));
                stats.put("distribucion", dist);
                break;
            case "numerico":
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
            case "texto":
            case "area_texto":
                stats.put("valoresUnicos", valores.stream().distinct().count());
                stats.put("valorMasComun", valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting()))
                        .entrySet().stream()
                        .max((a, b) -> a.getValue().compareTo(b.getValue()))
                        .map(Map.Entry::getKey)
                        .orElse(null));
                break;
            case "fecha":
                stats.put("totalFechas", valores.size());
                stats.put("formatosDetectados", valores.stream().distinct().count());
                break;
            default:
                stats.put("totalRegistrado", valores.size());
        }

        return stats;
    }

    private static class Encabezado {
        private String nombre;
        private String tipoCampo;
        private List<String> opciones = new ArrayList<>();

        public String getNombre() { return nombre; }
        public void setNombre(String nombre) { this.nombre = nombre; }
        public String getTipoCampo() { return tipoCampo; }
        public void setTipoCampo(String tipoCampo) { this.tipoCampo = tipoCampo; }
        public List<String> getOpciones() { return opciones; }
        public void setOpciones(List<String> opciones) { this.opciones = opciones; }
    }
}
