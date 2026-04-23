package co.edu.uceva.microserviciojustificacion.infrastructure.rest.dto;

import co.edu.uceva.microserviciojustificacion.domain.model.Justificacion;
import co.edu.uceva.microserviciojustificacion.domain.service.IJustificacionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/justificaciones")
public class JustificacionController {

    private final IJustificacionService justificacionService;

    public JustificacionController(IJustificacionService justificacionService) {
        this.justificacionService = justificacionService;
    }

    @PostMapping("/solicitar")
    public ResponseEntity<JustificacionDTO> solicitarJustificacion(@RequestBody JustificacionRequest requestBody) {
    Justificacion saved = justificacionService.solicitarJustificacion(
        requestBody.getRegistroId(),
        requestBody.getUsuarioCodigo(),
        requestBody.getMotivo(),
        requestBody.getDocumentoUrl()
    );

    JustificacionDTO response = convertToDTO(saved);
    return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/{id}/aprobar")
        public ResponseEntity<JustificacionDTO> aprobarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest requestBody) {
        Justificacion updated = justificacionService.aprobarJustificacion(
            id,
            requestBody.getRevisadoPor(),
            requestBody.getObservaciones()
        );
        JustificacionDTO response = convertToDTO(updated);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/rechazar")
        public ResponseEntity<JustificacionDTO> rechazarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest requestBody) {
        Justificacion updated = justificacionService.rechazarJustificacion(
            id,
            requestBody.getRevisadoPor(),
            requestBody.getObservaciones()
        );
        JustificacionDTO response = convertToDTO(updated);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<JustificacionDTO> findById(@PathVariable Long id) {
        Justificacion result = justificacionService.findById(id);
        JustificacionDTO dto = convertToDTO(result);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/usuario/{usuarioCodigo}")
    public ResponseEntity<List<JustificacionDTO>> findByUsuarioCodigo(@PathVariable String usuarioCodigo) {
        List<JustificacionDTO> response = justificacionService.findByUsuarioCodigo(usuarioCodigo)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/registro/{registroId}")
    public ResponseEntity<List<JustificacionDTO>> findByRegistroId(@PathVariable Long registroId) {
        List<JustificacionDTO> response = justificacionService.findByRegistroId(registroId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/estado/{estado}")
    public ResponseEntity<List<JustificacionDTO>> findByEstado(@PathVariable String estado) {
        List<JustificacionDTO> response = justificacionService.findByEstado(estado)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/justificaciones")
    public ResponseEntity<List<JustificacionDTO>> findAll() {
        List<JustificacionDTO> response = justificacionService.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<JustificacionDTO> update(@PathVariable Long id, @RequestBody JustificacionDTO dto) {
        Justificacion justificacion = convertToEntity(dto);
        justificacion.setId(id);
        Justificacion updated = justificacionService.update(justificacion);
        JustificacionDTO response = convertToDTO(updated);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        justificacionService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private JustificacionDTO convertToDTO(Justificacion entity) {
        if (entity == null) {
            return null;
        }

        JustificacionDTO dto = new JustificacionDTO();
        dto.setId(entity.getId() != null ? entity.getId().toString() : null);
        dto.setRegistroId(entity.getRegistroId() != null ? entity.getRegistroId().toString() : null);
        dto.setMotivo(entity.getMotivo());
        dto.setDocumentoUrl(entity.getDocumentoUrl());
        dto.setEstado(entity.getEstado());
        dto.setUsuarioCodigo(entity.getUsuarioCodigo());
        dto.setFechaSolicitud(entity.getFechaSolicitud());
        dto.setFechaRevision(entity.getFechaRevision());
        dto.setRevisadoPor(entity.getRevisadoPor());
        dto.setObservaciones(entity.getObservaciones());
        return dto;
    }

    private Justificacion convertToEntity(JustificacionDTO dto) {
        if (dto == null) {
            return null;
        }

        Justificacion entity = new Justificacion();
        if (dto.getId() != null && !dto.getId().isEmpty()) {
            entity.setId(Long.parseLong(dto.getId()));
        }
        if (dto.getRegistroId() != null && !dto.getRegistroId().isEmpty()) {
            entity.setRegistroId(Long.parseLong(dto.getRegistroId()));
        }
        entity.setMotivo(dto.getMotivo());
        entity.setDocumentoUrl(dto.getDocumentoUrl());
        entity.setEstado(dto.getEstado());
        entity.setUsuarioCodigo(dto.getUsuarioCodigo());
        entity.setFechaSolicitud(dto.getFechaSolicitud());
        entity.setFechaRevision(dto.getFechaRevision());
        entity.setRevisadoPor(dto.getRevisadoPor());
        entity.setObservaciones(dto.getObservaciones());
        return entity;
    }

}
