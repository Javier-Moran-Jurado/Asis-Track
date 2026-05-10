package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.JustificacionDTO;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.JustificacionRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.RevisionRequest;
import co.edu.uceva.microservicioplanilla.domain.model.EstadoJustificacion;
import co.edu.uceva.microservicioplanilla.domain.model.Justificacion;
import co.edu.uceva.microservicioplanilla.domain.service.IJustificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/planilla-service/justificaciones")
@RequiredArgsConstructor
public class JustificacionRestController {

    private final IJustificacionService justificacionService;

    @PreAuthorize("isAuthenticated() and hasAnyRole('Estudiante', 'Monitor', 'Docente', 'Administrador', 'Administrativo')")
    @PostMapping("/solicitar")
    public ResponseEntity<JustificacionDTO> solicitarJustificacion(@RequestBody JustificacionRequest request) {
        Justificacion saved = justificacionService.solicitarJustificacion(
                request.getEventoId(),
                request.getCodigoEstudiante(),
                request.getMotivo(),
                request.getDocumentoUrl()
        );
        return new ResponseEntity<>(convertToDTO(saved), HttpStatus.CREATED);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @PostMapping("/{id}/aprobar")
    public ResponseEntity<JustificacionDTO> aprobarJustificacion(@PathVariable Long id, @RequestBody RevisionRequest request) {
        Justificacion updated = justificacionService.aprobarJustificacion(id, request.getCodigoDecano(), request.getObservaciones());
        return ResponseEntity.ok(convertToDTO(updated));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @PostMapping("/{id}/rechazar")
    public ResponseEntity<JustificacionDTO> rechazarJustificacion(@PathVariable Long id, @RequestBody RevisionRequest request) {
        Justificacion updated = justificacionService.rechazarJustificacion(id, request.getCodigoDecano(), request.getObservaciones());
        return ResponseEntity.ok(convertToDTO(updated));
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/{id}")
    public ResponseEntity<JustificacionDTO> findById(@PathVariable Long id) {
        return ResponseEntity.ok(convertToDTO(justificacionService.findById(id)));
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/estudiante/{codigoEstudiante}")
    public ResponseEntity<List<JustificacionDTO>> findByCodigoEstudiante(@PathVariable Long codigoEstudiante) {
        List<JustificacionDTO> response = justificacionService.findByCodigoEstudiante(codigoEstudiante)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/evento/{eventoId}")
    public ResponseEntity<List<JustificacionDTO>> findByEventoId(@PathVariable Long eventoId) {
        List<JustificacionDTO> response = justificacionService.findByEventoId(eventoId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @GetMapping("/estado/{estado}")
    public ResponseEntity<List<JustificacionDTO>> findByEstado(@PathVariable EstadoJustificacion estado) {
        List<JustificacionDTO> response = justificacionService.findByEstado(estado)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @GetMapping("/all")
    public ResponseEntity<List<JustificacionDTO>> findAll() {
        List<JustificacionDTO> response = justificacionService.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @PutMapping("/{id}")
    public ResponseEntity<JustificacionDTO> update(@PathVariable Long id, @RequestBody JustificacionDTO dto) {
        Justificacion justificacion = convertToEntity(dto);
        justificacion.setId(id);
        Justificacion updated = justificacionService.update(justificacion);
        return ResponseEntity.ok(convertToDTO(updated));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo', 'Decano')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        justificacionService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private JustificacionDTO convertToDTO(Justificacion entity) {
        if (entity == null) return null;
        JustificacionDTO dto = new JustificacionDTO();
        dto.setId(entity.getId());
        dto.setEventoId(entity.getEvento() != null ? entity.getEvento().getId() : null);
        dto.setCodigoEstudiante(entity.getCodigoEstudiante());
        dto.setCodigoDecano(entity.getCodigoDecano());
        dto.setMotivo(entity.getMotivo());
        dto.setDocumentoUrl(entity.getDocumentoUrl());
        dto.setEstado(entity.getEstado());
        dto.setFechaSolicitud(entity.getFechaSolicitud());
        dto.setFechaRevision(entity.getFechaRevision());
        dto.setObservaciones(entity.getObservaciones());
        return dto;
    }

    private Justificacion convertToEntity(JustificacionDTO dto) {
        if (dto == null) return null;
        Justificacion entity = new Justificacion();
        entity.setId(dto.getId());
        entity.setCodigoEstudiante(dto.getCodigoEstudiante());
        entity.setCodigoDecano(dto.getCodigoDecano());
        entity.setMotivo(dto.getMotivo());
        entity.setDocumentoUrl(dto.getDocumentoUrl());
        entity.setEstado(dto.getEstado());
        entity.setFechaSolicitud(dto.getFechaSolicitud());
        entity.setFechaRevision(dto.getFechaRevision());
        entity.setObservaciones(dto.getObservaciones());
        // Note: evento must be set separately via service layer
        return entity;
    }
}
