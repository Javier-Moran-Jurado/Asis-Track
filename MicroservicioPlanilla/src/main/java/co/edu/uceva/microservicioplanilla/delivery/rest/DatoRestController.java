package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.service.IDatoService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoRequest;
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
    public ResponseEntity<List<Dato>> findAll() {
        return ResponseEntity.ok(datoService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Dato> findById(@PathVariable Long id) {
        return ResponseEntity.ok(datoService.findById(id));
    }

    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<Dato>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(datoService.findByPlanillaId(planillaId));
    }

    @GetMapping("/planilla/{planillaId}/fila/{indice}")
    public ResponseEntity<List<Dato>> findByPlanillaIdAndIndice(
            @PathVariable Long planillaId,
            @PathVariable Integer indice) {
        return ResponseEntity.ok(datoService.findByPlanillaIdAndIndice(planillaId, indice));
    }

    @GetMapping("/campo/{campoId}")
    public ResponseEntity<List<Dato>> findByCampoId(@PathVariable Long campoId) {
        return ResponseEntity.ok(datoService.findByCampoId(campoId));
    }

    @PostMapping
    public ResponseEntity<Dato> save(@RequestBody Dato dato) {
        return ResponseEntity.status(HttpStatus.CREATED).body(datoService.save(dato));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Dato> update(@PathVariable Long id, @RequestBody Dato dato) {
        dato.setId(id);
        return ResponseEntity.ok(datoService.update(dato));
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
            return ResponseEntity.status(HttpStatus.CREATED).body(datoService.saveAll(requests));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("status", 400, "message", e.getMessage()));
        }
    }
}
