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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/eventos")
@RequiredArgsConstructor
public class EventoRestController {

    private final IEventoService eventoService;
    private final ILugarService lugarService;
    private final IPlanillaRepository planillaRepository;

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public ResponseEntity<List<EventoResponse>> findAll() {
        Long currentUser = getCurrentUserCodigo();
        boolean isAdmin = isAdminOrAdministrativo();

        List<Evento> eventos;
        if (isAdmin) {
            eventos = eventoService.findAll();
        } else {
            eventos = eventoService.findByCodigoUsuario(currentUser);
        }

        List<EventoResponse> responses = eventos.stream()
                .map(e -> EventoResponse.from(e, planillaRepository.findByEventoId(e.getId())))
                .toList();
        return ResponseEntity.ok(responses);
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/{id}")
    public ResponseEntity<EventoResponse> findById(@PathVariable Long id) {
        Evento evento = eventoService.findById(id);
        Long currentUser = getCurrentUserCodigo();
        boolean isAdmin = isAdminOrAdministrativo();

        if (!isAdmin && !evento.getCodigoUsuario().equals(currentUser)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No tienes permiso para ver este evento");
        }

        return ResponseEntity.ok(EventoResponse.from(evento, planillaRepository.findByEventoId(id)));
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/usuario/{codigoUsuario}")
    public ResponseEntity<List<EventoResponse>> findByCodigoUsuario(@PathVariable Long codigoUsuario) {
        Long currentUser = getCurrentUserCodigo();
        boolean isAdmin = isAdminOrAdministrativo();

        if (!isAdmin && !codigoUsuario.equals(currentUser)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No tienes permiso para ver eventos de otro usuario");
        }

        List<EventoResponse> responses = eventoService.findByCodigoUsuario(codigoUsuario).stream()
                .map(e -> EventoResponse.from(e, planillaRepository.findByEventoId(e.getId())))
                .toList();
        return ResponseEntity.ok(responses);
    }

    @PreAuthorize("isAuthenticated() and !hasRole('Estudiante')")
    @PostMapping
    public ResponseEntity<EventoResponse> save(@RequestBody EventoRequest request) {
        Long currentUser = getCurrentUserCodigo();
        if (request.getCodigoUsuario() == null) {
            request.setCodigoUsuario(currentUser);
        }
        Evento entity = toEntity(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(EventoResponse.from(eventoService.save(entity)));
    }

    @PreAuthorize("isAuthenticated() and !hasRole('Estudiante')")
    @PutMapping("/{id}")
    public ResponseEntity<EventoResponse> update(@PathVariable Long id, @RequestBody EventoRequest request) {
        Evento existente = eventoService.findById(id);
        Long currentUser = getCurrentUserCodigo();
        boolean isAdmin = isAdminOrAdministrativo();

        if (!isAdmin && !existente.getCodigoUsuario().equals(currentUser)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No tienes permiso para modificar este evento");
        }

        Evento entity = toEntity(request);
        entity.setId(id);
        return ResponseEntity.ok(EventoResponse.from(eventoService.update(entity), planillaRepository.findByEventoId(id)));
    }

    @PreAuthorize("isAuthenticated() and !hasRole('Estudiante')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        Evento existente = eventoService.findById(id);
        Long currentUser = getCurrentUserCodigo();
        boolean isAdmin = isAdminOrAdministrativo();

        if (!isAdmin && !existente.getCodigoUsuario().equals(currentUser)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No tienes permiso para eliminar este evento");
        }

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

    private Long getCurrentUserCodigo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetails userDetails) {
            return Long.parseLong(userDetails.getUsername());
        }
        return null;
    }

    private boolean isAdminOrAdministrativo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_Administrador") || a.getAuthority().equals("ROLE_Administrativo"));
    }
}
