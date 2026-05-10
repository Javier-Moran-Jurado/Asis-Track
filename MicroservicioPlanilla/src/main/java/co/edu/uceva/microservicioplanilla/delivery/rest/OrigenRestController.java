package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import co.edu.uceva.microservicioplanilla.domain.service.IOrigenService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/origenes")
@RequiredArgsConstructor
public class OrigenRestController {

    private final IOrigenService origenService;

    @GetMapping
    public ResponseEntity<List<Origen>> findAll() {
        return ResponseEntity.ok(origenService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Origen> findById(@PathVariable Long id) {
        return ResponseEntity.ok(origenService.findById(id));
    }

    @PostMapping
    public ResponseEntity<Origen> save(@RequestBody Origen origen) {
        return ResponseEntity.status(HttpStatus.CREATED).body(origenService.save(origen));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Origen> update(@PathVariable Long id, @RequestBody Origen origen) {
        origen.setId(id);
        return ResponseEntity.ok(origenService.update(origen));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        origenService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
