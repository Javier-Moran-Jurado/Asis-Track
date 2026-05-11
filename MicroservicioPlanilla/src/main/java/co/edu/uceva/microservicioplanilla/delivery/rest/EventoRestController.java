package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.domain.service.IEventoService;
import co.edu.uceva.microservicioplanilla.domain.service.ILugarService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EventoRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.EventoResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/eventos")
@RequiredArgsConstructor
public class EventoRestController {

    private final IEventoService eventoService;
    private final ILugarService lugarService;
    private final IPlanillaRepository planillaRepository;

    @GetMapping
    public ResponseEntity<List<EventoResponse>> findAll() {
        List<EventoResponse> responses = eventoService.findAll().stream()
                .map(e -> EventoResponse.from(e, planillaRepository.findByEventoId(e.getId())))
                .toList();
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventoResponse> findById(@PathVariable Long id) {
        Evento evento = eventoService.findById(id);
        return ResponseEntity.ok(EventoResponse.from(evento, planillaRepository.findByEventoId(id)));
    }

    @GetMapping("/usuario/{codigoUsuario}")
    public ResponseEntity<List<EventoResponse>> findByCodigoUsuario(@PathVariable Long codigoUsuario) {
        List<EventoResponse> responses = eventoService.findByCodigoUsuario(codigoUsuario).stream()
                .map(e -> EventoResponse.from(e, planillaRepository.findByEventoId(e.getId())))
                .toList();
        return ResponseEntity.ok(responses);
    }

    @PostMapping
    public ResponseEntity<EventoResponse> save(@RequestBody EventoRequest request) {
        Evento entity = toEntity(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(EventoResponse.from(eventoService.save(entity)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventoResponse> update(@PathVariable Long id, @RequestBody EventoRequest request) {
        Evento entity = toEntity(request);
        entity.setId(id);
        return ResponseEntity.ok(EventoResponse.from(eventoService.update(entity), planillaRepository.findByEventoId(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        eventoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private Evento toEntity(EventoRequest request) {
        Evento entity = new Evento();
        entity.setNombre(request.getNombre());
        entity.setDescripcion(request.getDescripcion());
        entity.setCodigoUsuario(request.getCodigoUsuario());
        entity.setFechaHoraInicio(request.getFechaHoraInicio());
        entity.setFechaHoraFin(request.getFechaHoraFin());
        entity.setFechaCreacion(LocalDateTime.now());
        if (request.getLugarId() != null) {
            entity.setLugar(lugarService.findById(request.getLugarId()));
        }
        return entity;
    }
}
