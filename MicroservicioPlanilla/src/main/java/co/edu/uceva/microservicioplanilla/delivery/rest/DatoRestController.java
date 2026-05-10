package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.service.IDatoService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Validated
@RestController
@RequestMapping("/api/v1/planilla-service/datos")
@RequiredArgsConstructor
public class DatoRestController {

    private final IDatoService datoService;

    @GetMapping
    public ResponseEntity<List<DatoResponse>> findAll() {
        return ResponseEntity.ok(toResponse(datoService.findAll()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DatoResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(toResponse(datoService.findById(id)));
    }

    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<DatoResponse>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(toResponse(datoService.findByPlanillaId(planillaId)));
    }

    @GetMapping("/campo/{campoId}")
    public ResponseEntity<List<DatoResponse>> findByCampoId(@PathVariable Long campoId) {
        return ResponseEntity.ok(toResponse(datoService.findByCampoId(campoId)));
    }

    @PostMapping
    public ResponseEntity<DatoResponse> save(@RequestBody @Valid DatoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(datoService.save(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DatoResponse> update(@PathVariable Long id, @RequestBody @Valid DatoRequest request) {
        return ResponseEntity.ok(toResponse(datoService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        datoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/batch")
    public ResponseEntity<?> saveAll(@RequestBody @Size(max = 1000) List<DatoRequest> requests) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(datoService.saveAll(requests)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("status", 400, "message", e.getMessage()));
        }
    }

    private List<DatoResponse> toResponse(List<Dato> datos) {
        return datos.stream().map(this::toResponse).toList();
    }

    private DatoResponse toResponse(Dato d) {
        DatoResponse resp = new DatoResponse();
        resp.setId(d.getId());
        resp.setCampoId(d.getCampo() != null ? d.getCampo().getId() : null);
        resp.setFilaId(d.getFila() != null ? d.getFila().getId() : null);
        resp.setPosicion(d.getPosicion());
        resp.setInformacion(d.getInformacion());
        return resp;
    }
}
