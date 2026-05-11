package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.domain.model.*;
import co.edu.uceva.microservicioplanilla.domain.repository.*;
import co.edu.uceva.microservicioplanilla.domain.service.ai.AiPromptFactory;
import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GeneradorPlanillaServiceImpl implements GeneradorPlanillaService {

    private final CompositeAiService compositeAiService;
    private final AiPromptFactory promptFactory;
    private final ITipoCampoRepository tipoCampoRepository;
    private final IEventoService eventoService;
    private final IPlanillaService planillaService;
    private final ICampoService campoService;
    private final ILugarRepository lugarRepository;
    private final IOrigenRepository origenRepository;
    private final ObjectMapper objectMapper;

    @Override
    public PlanillaPropuestaResponse generarPropuesta(GenerarPropuestaRequest request) {
        String tiposPermitidos = compositeAiService.getTiposPermitidosFormateados();
        String prompt = promptFactory.buildPlanillaFromDescriptionPrompt(
                request.getDescripcion(), request.isCrearEvento(), tiposPermitidos);

        String rawResponse = compositeAiService.generateFromText(prompt);
        return parsearPropuesta(rawResponse, request.isCrearEvento());
    }

    @Override
    @Transactional
    public Planilla confirmarPropuesta(ConfirmarPropuestaRequest request) {
        Evento evento = null;
        if (request.getEvento() != null) {
            EventoConfirmadoRequest er = request.getEvento();
            Evento e = new Evento();
            e.setNombre(er.getNombre());
            e.setDescripcion(er.getDescripcion());
            e.setFechaHoraInicio(er.getFechaHoraInicio());
            e.setFechaHoraFin(er.getFechaHoraFin());
            e.setFechaCreacion(LocalDateTime.now());
            if (er.getLugarId() != null) {
                Lugar lugar = lugarRepository.findById(er.getLugarId())
                        .orElseThrow(() -> new RuntimeException("Lugar no encontrado: " + er.getLugarId()));
                e.setLugar(lugar);
            }
            evento = eventoService.save(e);
        }

        Origen origenDigital = origenRepository.findByOrigenIgnoreCase("digital")
                .orElseThrow(() -> new RuntimeException("Origen 'digital' no encontrado"));

        Planilla planilla = new Planilla();
        planilla.setOrigen(origenDigital);
        planilla.setEvento(evento);
        planilla = planillaService.save(planilla);

        if (request.getCampos() != null && !request.getCampos().isEmpty()) {
            for (CampoRequest cr : request.getCampos()) {
                cr.setPlanillaId(planilla.getId());
            }
            campoService.saveAll(request.getCampos());
        }

        return planilla;
    }

    private PlanillaPropuestaResponse parsearPropuesta(String rawResponse, boolean esperaEvento) {
        String json = extraerJson(rawResponse);
        List<CampoPropuestoResponse> camposPropuestos = new ArrayList<>();
        EventoPropuestoResponse eventoPropuesto = null;

        try {
            JsonNode root = objectMapper.readTree(json);

            if (esperaEvento) {
                JsonNode eventoNode = root.has("nombre_evento") ? root : root.path("evento");

                String nombreEvento = optText(eventoNode, "nombre_evento");
                String descEvento = optText(eventoNode, "descripcion_evento");
                String fechaInicio = optText(eventoNode, "fecha_hora_inicio");
                String fechaFin = optText(eventoNode, "fecha_hora_fin");
                String lugarNombre = optText(eventoNode, "lugar_nombre");

                if (nombreEvento != null) {
                    eventoPropuesto = new EventoPropuestoResponse();
                    eventoPropuesto.setNombre(nombreEvento);
                    eventoPropuesto.setDescripcion(descEvento);
                    eventoPropuesto.setFechaHoraInicio(parseIso(fechaInicio));
                    eventoPropuesto.setFechaHoraFin(parseIso(fechaFin));
                    eventoPropuesto.setLugarNombre(lugarNombre);
                }
            }

            JsonNode camposNode = root.path("campos");
            if (camposNode.isArray()) {
                camposPropuestos = parsearCampos(camposNode);
            } else if (root.isArray()) {
                // Fallback: si la raíz es un array de campos
                camposPropuestos = parsearCampos(root);
            }
        } catch (Exception e) {
            // Si el JSON es un array puro
            try {
                JsonNode arr = objectMapper.readTree(json);
                if (arr.isArray()) {
                    camposPropuestos = parsearCampos(arr);
                }
            } catch (Exception ignored) {}
        }

        validarTipos(camposPropuestos);

        PlanillaPropuestaResponse resp = new PlanillaPropuestaResponse();
        resp.setEvento(eventoPropuesto);
        resp.setCampos(camposPropuestos);
        return resp;
    }

    private List<CampoPropuestoResponse> parsearCampos(JsonNode camposNode) {
        List<CampoPropuestoResponse> resultado = new ArrayList<>();
        for (JsonNode nodo : camposNode) {
            CampoPropuestoResponse c = new CampoPropuestoResponse();
            c.setNombreCampo(optText(nodo, "nombre_campo"));
            c.setTipoCampo(optText(nodo, "tipo_campo"));
            c.setObligatorio(nodo.path("obligatorio").asBoolean(false));

            JsonNode opcionesNode = nodo.path("opciones");
            if (opcionesNode.isArray()) {
                List<String> opciones = new ArrayList<>();
                for (JsonNode op : opcionesNode) {
                    opciones.add(op.asText());
                }
                c.setOpciones(opciones);
            }
            resultado.add(c);
        }
        return resultado;
    }

    private void validarTipos(List<CampoPropuestoResponse> campos) {
        if (campos == null || campos.isEmpty()) return;
        Set<String> tiposValidos = tipoCampoRepository.findAll().stream()
                .map(TipoCampo::getTipo)
                .collect(Collectors.toSet());

        for (CampoPropuestoResponse c : campos) {
            if (c.getTipoCampo() != null && !tiposValidos.contains(c.getTipoCampo())) {
                throw new IllegalArgumentException("Tipo de campo no válido propuesto por IA: " + c.getTipoCampo());
            }
        }
    }

    private String extraerJson(String raw) {
        if (raw == null) return "[]";
        raw = raw.trim();
        // Buscar bloque JSON entre backticks
        Pattern pattern = Pattern.compile("```(?:json)?\\s*([\\s\\S]*?)\\s*```");
        Matcher matcher = pattern.matcher(raw);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        // Si empieza con { o [, devolver directo
        if (raw.startsWith("{") || raw.startsWith("[")) {
            return raw;
        }
        // Buscar primer { o [
        int firstObj = raw.indexOf('{');
        int firstArr = raw.indexOf('[');
        int start = -1;
        if (firstObj >= 0 && firstArr >= 0) {
            start = Math.min(firstObj, firstArr);
        } else if (firstObj >= 0) {
            start = firstObj;
        } else if (firstArr >= 0) {
            start = firstArr;
        }
        if (start >= 0) {
            return raw.substring(start);
        }
        return "[]";
    }

    private String optText(JsonNode node, String field) {
        JsonNode n = node.path(field);
        return n.isMissingNode() || n.isNull() ? null : n.asText();
    }

    private LocalDateTime parseIso(String value) {
        if (value == null || value.isBlank() || "null".equalsIgnoreCase(value)) return null;
        try {
            return LocalDateTime.parse(value);
        } catch (Exception e) {
            try {
                return java.time.Instant.parse(value).atZone(java.time.ZoneId.systemDefault()).toLocalDateTime();
            } catch (Exception ex) {
                return null;
            }
        }
    }
}
