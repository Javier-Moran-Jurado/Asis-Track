package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;
import co.edu.uceva.microservicioplanilla.domain.service.ILugarService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/lugares")
@RequiredArgsConstructor
public class LugarRestController {

    private final ILugarService lugarService;

    @GetMapping
    public ResponseEntity<List<Lugar>> findAll() {
        return ResponseEntity.ok(lugarService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Lugar> findById(@PathVariable Long id) {
        return ResponseEntity.ok(lugarService.findById(id));
    }

    @PostMapping
    public ResponseEntity<Lugar> save(@RequestBody Lugar lugar) {
        return ResponseEntity.status(HttpStatus.CREATED).body(lugarService.save(lugar));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Lugar> update(@PathVariable Long id, @RequestBody Lugar lugar) {
        lugar.setId(id);
        return ResponseEntity.ok(lugarService.update(lugar));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        lugarService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
