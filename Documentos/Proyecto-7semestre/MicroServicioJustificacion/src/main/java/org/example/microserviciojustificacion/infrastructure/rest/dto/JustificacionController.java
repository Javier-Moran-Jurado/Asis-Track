package org.example.microserviciojustificacion.infrastructure.rest.dto;

import org.example.microserviciojustificacion.domain.model.Justificacion;
import org.example.microserviciojustificacion.domain.service.IJustificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/justificaciones")
@RequiredArgsConstructor
public class JustificacionController {

    private final IJustificacionService justificacionService;

    @PostMapping("/solicitar")
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
    public ResponseEntity<Justificacion> aprobarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest request) {
        return ResponseEntity.ok(
                justificacionService.aprobarJustificacion(id, request.getRevisadoPor(), request.getObservaciones())
        );
    }

    @PostMapping("/{id}/rechazar")
    public ResponseEntity<Justificacion> rechazarJustificacion(
            @PathVariable Long id,
            @RequestBody RevisionRequest request) {
        return ResponseEntity.ok(
                justificacionService.rechazarJustificacion(id, request.getRevisadoPor(), request.getObservaciones())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<Justificacion> findById(@PathVariable Long id) {
        return ResponseEntity.ok(justificacionService.findById(id));
    }

    @GetMapping("/usuario/{usuarioCodigo}")
    public ResponseEntity<List<Justificacion>> findByUsuarioCodigo(@PathVariable String usuarioCodigo) {
        return ResponseEntity.ok(justificacionService.findByUsuarioCodigo(usuarioCodigo));
    }

    @GetMapping("/registro/{registroId}")
    public ResponseEntity<List<Justificacion>> findByRegistroId(@PathVariable Long registroId) {
        return ResponseEntity.ok(justificacionService.findByRegistroId(registroId));
    }

    @GetMapping("/estado/{estado}")
    public ResponseEntity<List<Justificacion>> findByEstado(@PathVariable String estado) {
        return ResponseEntity.ok(justificacionService.findByEstado(estado));
    }

    @GetMapping
    public ResponseEntity<List<Justificacion>> findAll() {
        return ResponseEntity.ok(justificacionService.findAll());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Justificacion> update(@PathVariable Long id, @RequestBody Justificacion justificacion) {
        justificacion.setId(id);
        return ResponseEntity.ok(justificacionService.update(justificacion));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        justificacionService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
