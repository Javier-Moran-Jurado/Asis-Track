package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.service.ITipoCampoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/tipos-campo")
@RequiredArgsConstructor
public class TipoCampoRestController {

    private final ITipoCampoService tipoCampoService;

    @GetMapping
    public ResponseEntity<List<TipoCampo>> findAll() {
        return ResponseEntity.ok(tipoCampoService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TipoCampo> findById(@PathVariable Long id) {
        return ResponseEntity.ok(tipoCampoService.findById(id));
    }

    @PostMapping
    public ResponseEntity<TipoCampo> save(@RequestBody TipoCampo tipoCampo) {
        return ResponseEntity.status(HttpStatus.CREATED).body(tipoCampoService.save(tipoCampo));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TipoCampo> update(@PathVariable Long id, @RequestBody TipoCampo tipoCampo) {
        tipoCampo.setId(id);
        return ResponseEntity.ok(tipoCampoService.update(tipoCampo));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        tipoCampoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
