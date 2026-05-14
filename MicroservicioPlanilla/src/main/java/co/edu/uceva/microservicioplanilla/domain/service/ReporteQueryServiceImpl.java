package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.domain.model.*;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IEventoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IJustificacionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReporteQueryServiceImpl implements IReporteQueryService {

    private final IEventoRepository eventoRepository;
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
    public EstadisticasEventoResponse estadisticasCompletasEvento(Long eventoId, Integer bins) {
        Evento evento = eventoRepository.findById(eventoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Evento no encontrado: " + eventoId));

        List<Dato> todosLosDatos = datoRepository.findDatosByEventoId(eventoId);
        List<Campo> campos = extraerCamposUnicos(todosLosDatos);

        int totalFilas = (int) todosLosDatos.stream()
                .map(d -> d.getFila().getId())
                .distinct()
                .count();

        EstadisticasEventoResponse response = new EstadisticasEventoResponse();
        response.setEventoId(evento.getId());
        response.setNombreEvento(evento.getNombre());
        response.setTotalPlanillas(campos.isEmpty() ? 0 : campos.get(0).getPlanilla().getId() != null ? 1 : 0);
        response.setTotalFilas(totalFilas);
        response.setCampos(campos.stream()
                .map(c -> construirEstadisticasCampo(c, todosLosDatos.stream()
                        .filter(d -> d.getCampo().getId().equals(c.getId()))
                        .collect(Collectors.toList()), bins))
                .collect(Collectors.toList()));

        return response;
    }

    @Override
    public EstadisticasCampoResponse estadisticasPorCampoEvento(Long eventoId, String nombreCampo, Integer bins) {
        Evento evento = eventoRepository.findById(eventoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Evento no encontrado: " + eventoId));

        List<Dato> datos = datoRepository.findByEventoIdAndNombreCampo(eventoId, nombreCampo);
        if (datos.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Campo no encontrado para el evento: " + nombreCampo);
        }

        Campo campo = datos.get(0).getCampo();
        return construirEstadisticasCampo(campo, datos, bins);
    }

    @Override
    public EstadisticasEventoResponse comparativaCamposEvento(Long eventoId, List<String> nombresCampos, Integer bins) {
        Evento evento = eventoRepository.findById(eventoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Evento no encontrado: " + eventoId));

        List<Dato> todosLosDatos = datoRepository.findDatosByEventoId(eventoId);
        List<Campo> campos = extraerCamposUnicos(todosLosDatos).stream()
                .filter(c -> nombresCampos.contains(c.getNombreCampo()))
                .collect(Collectors.toList());

        int totalFilas = (int) todosLosDatos.stream()
                .map(d -> d.getFila().getId())
                .distinct()
                .count();

        EstadisticasEventoResponse response = new EstadisticasEventoResponse();
        response.setEventoId(evento.getId());
        response.setNombreEvento(evento.getNombre());
        response.setTotalPlanillas(1);
        response.setTotalFilas(totalFilas);
        response.setCampos(campos.stream()
                .map(c -> construirEstadisticasCampo(c, todosLosDatos.stream()
                        .filter(d -> d.getCampo().getId().equals(c.getId()))
                        .collect(Collectors.toList()), bins))
                .collect(Collectors.toList()));

        return response;
    }

    private List<Campo> extraerCamposUnicos(List<Dato> datos) {
        return datos.stream()
                .map(Dato::getCampo)
                .filter(c -> !List.of("signature_file", "file").contains(c.getTipoCampo().getTipo()))
                .distinct()
                .sorted(Comparator.comparing(Campo::getId))
                .collect(Collectors.toList());
    }

    private EstadisticasCampoResponse construirEstadisticasCampo(Campo campo, List<Dato> datos, Integer bins) {
        EstadisticasCampoResponse response = new EstadisticasCampoResponse();
        response.setCampo(campo.getNombreCampo());
        response.setTipoCampo(campo.getTipoCampo().getTipo());
        response.setTotalRegistros(datos.size());

        List<String> valores = datos.stream()
                .map(Dato::getInformacion)
                .filter(v -> v != null && !v.isEmpty())
                .collect(Collectors.toList());

        response.setConRespuestas(valores.size());
        response.setSinRespuestas(datos.size() - valores.size());
        response.setEstadisticas(calcularEstadisticasTipadas(valores, campo.getTipoCampo().getTipo(), bins));

        return response;
    }

    private Object calcularEstadisticasTipadas(List<String> valores, String tipoCampo, Integer bins) {
        switch (tipoCampo) {
            case "combo":
            case "radio":
            case "checkbox":
            case "multivaluecheckbox":
                EstadisticasCategoricasResponse cat = new EstadisticasCategoricasResponse();
                cat.setConRespuestas(valores.size());
                cat.setSinRespuestas(0);
                cat.setDistribucion(valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting())));
                cat.setValores(valores);
                return cat;

            case "numeric":
                EstadisticasNumericasResponse num = new EstadisticasNumericasResponse();
                num.setConRespuestas(valores.size());
                num.setSinRespuestas(0);
                if (!valores.isEmpty()) {
                    List<Double> valoresNumericos = valores.stream()
                            .mapToDouble(v -> {
                                try { return Double.parseDouble(v); } catch (Exception e) { return 0.0; }
                            })
                            .boxed()
                            .collect(Collectors.toList());

                    DoubleSummaryStatistics summary = valoresNumericos.stream()
                            .mapToDouble(Double::doubleValue)
                            .summaryStatistics();

                    num.setMin(summary.getMin());
                    num.setMax(summary.getMax());
                    num.setPromedio(summary.getAverage());
                    num.setSuma(summary.getSum());
                    num.setCount(summary.getCount());
                    num.setDistribucionPorRango(calcularRangos(valoresNumericos, bins));
                }
                return num;

            case "text":
            case "email":
                EstadisticasTextoResponse txt = new EstadisticasTextoResponse();
                txt.setConRespuestas(valores.size());
                txt.setSinRespuestas(0);
                txt.setValoresUnicos(valores.stream().distinct().count());
                txt.setValorMasComun(valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting()))
                        .entrySet().stream()
                        .max(Comparator.comparingLong(Map.Entry::getValue))
                        .map(Map.Entry::getKey)
                        .orElse(null));
                txt.setFrecuencias(valores.stream()
                        .collect(Collectors.groupingBy(v -> v, Collectors.counting())));
                txt.setValores(valores);
                return txt;

            case "date":
                EstadisticasFechaResponse fecha = new EstadisticasFechaResponse();
                fecha.setConRespuestas(valores.size());
                fecha.setSinRespuestas(0);
                fecha.setTotalFechas(valores.size());
                fecha.setValoresUnicos(valores.stream().distinct().count());
                return fecha;

            default:
                EstadisticasTextoResponse def = new EstadisticasTextoResponse();
                def.setConRespuestas(valores.size());
                def.setSinRespuestas(0);
                def.setValoresUnicos(valores.stream().distinct().count());
                return def;
        }
    }

    private List<RangoEstadisticaResponse> calcularRangos(List<Double> valores, Integer bins) {
        if (valores.isEmpty()) return Collections.emptyList();

        double min = Collections.min(valores);
        double max = Collections.max(valores);

        if (min == max) {
            return List.of(new RangoEstadisticaResponse(min, max, (long) valores.size(), String.format("%.1f", min)));
        }

        int numBins = (bins != null) ? bins : (int) Math.ceil(Math.log(valores.size()) / Math.log(2)) + 1;
        numBins = Math.max(2, numBins);

        double step = (max - min) / numBins;

        List<RangoEstadisticaResponse> rangos = new ArrayList<>();
        for (int i = 0; i < numBins; i++) {
            double rangoMin = min + i * step;
            double rangoMax = (i == numBins - 1) ? max : min + (i + 1) * step;
            final double finalMin = rangoMin;
            final double finalMax = rangoMax;
            long count = valores.stream()
                    .filter(v -> v >= finalMin && v <= finalMax)
                    .count();
            rangos.add(new RangoEstadisticaResponse(
                    rangoMin,
                    rangoMax,
                    count,
                    String.format("%.1f - %.1f", rangoMin, rangoMax)
            ));
        }
        return rangos;
    }
}
