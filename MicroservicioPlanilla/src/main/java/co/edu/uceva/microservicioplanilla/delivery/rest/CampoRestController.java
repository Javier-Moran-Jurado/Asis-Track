package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.service.ICampoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/campos")
@RequiredArgsConstructor
public class CampoRestController {

    private final ICampoService campoService;

    @GetMapping
    public ResponseEntity<List<Campo>> findAll() {
        return ResponseEntity.ok(campoService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Campo> findById(@PathVariable Long id) {
        return ResponseEntity.ok(campoService.findById(id));
    }

    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<Campo>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(campoService.findByPlanillaId(planillaId));
    }

    @PostMapping
    public ResponseEntity<Campo> save(@RequestBody Campo campo) {
        return ResponseEntity.status(HttpStatus.CREATED).body(campoService.save(campo));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Campo> update(@PathVariable Long id, @RequestBody Campo campo) {
        campo.setId(id);
        return ResponseEntity.ok(campoService.update(campo));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        campoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
