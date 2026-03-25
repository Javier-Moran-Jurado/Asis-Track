package co.edu.uceva.microserviciojustificacion.infrastructure.rest.dto;

import co.edu.uceva.microserviciojustificacion.domain.model.Justificacion;
import co.edu.uceva.microserviciojustificacion.domain.service.IJustificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/justificaciones")
@RequiredArgsConstructor
public class JustificacionController {

    private final IJustificacionService justificacionService;

    @PostMapping("/solicitar")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Estudiante', 'Monitor')")
    public ResponseEntity<Justificacion> solicitarJustificacion(@RequestBody JustificacionRequest request) {
        return new ResponseEntity<>(
                justificacionService.solicitarJustificacion(
                        request.getRegistroId(),
                        request.getUsuarioCodigo(),
                        request.getMotivo(),
                        request.getDocumentoUrl()
                ),
                HttpStatus.CREATED
        );
    }

    @PostMapping("/{id}/aprobar")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<Justificacion> aprobarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest request) {
        return ResponseEntity.ok(
                justificacionService.aprobarJustificacion(id, request.getRevisadoPor(), request.getObservaciones())
        );
    }

    @PostMapping("/{id}/rechazar")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<Justificacion> rechazarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest request) {
        return ResponseEntity.ok(
                justificacionService.rechazarJustificacion(id, request.getRevisadoPor(), request.getObservaciones())
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<Justificacion> findById(@PathVariable Long id) {
        return ResponseEntity.ok(justificacionService.findById(id));
    }

    @GetMapping("/usuario/{usuarioCodigo}")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Estudiante', 'Monitor')")
    public ResponseEntity<List<Justificacion>> findByUsuarioCodigo(@PathVariable String usuarioCodigo) {
        return ResponseEntity.ok(justificacionService.findByUsuarioCodigo(usuarioCodigo));
    }

    @GetMapping("/registro/{registroId}")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<List<Justificacion>> findByRegistroId(@PathVariable Long registroId) {
        return ResponseEntity.ok(justificacionService.findByRegistroId(registroId));
    }

    @GetMapping("/estado/{estado}")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<List<Justificacion>> findByEstado(@PathVariable String estado) {
        return ResponseEntity.ok(justificacionService.findByEstado(estado));
    }

    @GetMapping("/justificaciones")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<List<Justificacion>> findAll() {
        return ResponseEntity.ok(justificacionService.findAll());
    }

    @PutMapping("/{id}")
    @PreAuthorize("isAuthenticated() and hasRole('Decano')")
    public ResponseEntity<Justificacion> update(@PathVariable Long id, @RequestBody Justificacion justificacion) {
        justificacion.setId(id);
        return ResponseEntity.ok(justificacionService.update(justificacion));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Decano')")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        justificacionService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
