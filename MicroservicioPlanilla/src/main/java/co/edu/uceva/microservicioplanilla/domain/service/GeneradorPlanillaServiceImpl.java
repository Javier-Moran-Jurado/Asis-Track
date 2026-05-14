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
    @Transactional
    public PlanillaResponse generarYGuardarPropuesta(String descripcion, Long lugarId, Long eventoId) {
        boolean crearEvento = (eventoId == null);
        String tiposPermitidos = compositeAiService.getTiposPermitidosFormateados();
        String prompt = promptFactory.buildPlanillaFromDescriptionPrompt(descripcion, crearEvento, tiposPermitidos);
        String rawResponse = compositeAiService.generateFromText(prompt);

        String json = extraerJson(rawResponse);
        JsonNode root;
        try {
            root = objectMapper.readTree(json);
        } catch (Exception e) {
            throw new RuntimeException("Error parseando respuesta IA: " + e.getMessage());
        }

        // 1. Resolver evento
        Evento evento;
        if (eventoId != null) {
            // Use existing event — skip AI-generated event fields
            evento = eventoService.findById(eventoId);
        } else {
            // Create event from AI response
            JsonNode eventoNode = root.has("nombre_evento") ? root : root.path("evento");
            String nombreEvento = optText(eventoNode, "nombre_evento");
            String descEvento = optText(eventoNode, "descripcion_evento");
            String fechaInicio = optText(eventoNode, "fecha_hora_inicio");
            String fechaFin = optText(eventoNode, "fecha_hora_fin");

            evento = new Evento();
            evento.setNombre(nombreEvento);
            evento.setDescripcion(descEvento);
            evento.setFechaHoraInicio(parseIso(fechaInicio));
            evento.setFechaHoraFin(parseIso(fechaFin));
            evento.setFechaCreacion(LocalDateTime.now());
            if (lugarId != null) {
                lugarRepository.findById(lugarId).ifPresent(evento::setLugar);
            }
            evento = eventoService.save(evento);
        }

        // 2. Crear planilla
        Origen origenDigital = origenRepository.findByOrigenIgnoreCase("digital")
                .orElseThrow(() -> new RuntimeException("Origen 'digital' no encontrado"));

        PlanillaRequest planillaReq = new PlanillaRequest();
        planillaReq.setOrigenId(origenDigital.getId());
        planillaReq.setEventoId(evento.getId());
        Planilla planilla = planillaService.save(planillaReq);

        // 3. Crear campos
        JsonNode camposNode = root.path("campos");
        if (camposNode.isArray()) {
            Set<String> tiposValidos = tipoCampoRepository.findAll().stream()
                    .map(TipoCampo::getTipo).collect(Collectors.toSet());

            List<CampoRequest> campoRequests = new ArrayList<>();
            for (JsonNode nodo : camposNode) {
                String tipoCampoStr = optText(nodo, "tipo_campo");
                if (tipoCampoStr != null && !tiposValidos.contains(tipoCampoStr)) {
                    throw new IllegalArgumentException("Tipo de campo no válido: " + tipoCampoStr);
                }
                TipoCampo tc = tipoCampoRepository.findAll().stream()
                        .filter(t -> t.getTipo().equalsIgnoreCase(tipoCampoStr))
                        .findFirst().orElse(null);
                if (tc == null) continue;

                CampoRequest cr = new CampoRequest();
                cr.setPlanillaId(planilla.getId());
                cr.setTipoCampoId(tc.getId());
                cr.setNombreCampo(optText(nodo, "nombre_campo"));
                cr.setObligatorio(nodo.path("obligatorio").asBoolean(false));
                // ── Read opciones from AI response ──
                JsonNode opcionesNode = nodo.path("opciones");
                if (opcionesNode.isArray()) {
                    List<String> opts = new ArrayList<>();
                    opcionesNode.forEach(o -> opts.add(o.asText()));
                    if (!opts.isEmpty()) cr.setOpciones(opts);
                }
                campoRequests.add(cr);
            }
            if (!campoRequests.isEmpty()) {
                campoService.saveAll(campoRequests);
            }
        }

        return PlanillaResponse.from(planillaService.findById(planilla.getId()));
    }

    private String extraerJson(String raw) {
        if (raw == null) return "[]";
        raw = raw.trim();
        Pattern pattern = Pattern.compile("```(?:json)?\\s*([\\s\\S]*?)\\s*```");
        Matcher matcher = pattern.matcher(raw);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        if (raw.startsWith("{") || raw.startsWith("[")) {
            return raw;
        }
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
