package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import co.edu.uceva.microservicioplanilla.domain.service.IOrigenService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.OrigenRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.OrigenResponse;
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
    public ResponseEntity<List<OrigenResponse>> findAll() {
        return ResponseEntity.ok(origenService.findAll().stream().map(OrigenResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrigenResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(OrigenResponse.from(origenService.findById(id)));
    }

    @PostMapping
    public ResponseEntity<OrigenResponse> save(@RequestBody OrigenRequest request) {
        Origen entity = new Origen();
        entity.setOrigen(request.getOrigen());
        return ResponseEntity.status(HttpStatus.CREATED).body(OrigenResponse.from(origenService.save(entity)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrigenResponse> update(@PathVariable Long id, @RequestBody OrigenRequest request) {
        Origen entity = origenService.findById(id);
        entity.setOrigen(request.getOrigen());
        return ResponseEntity.ok(OrigenResponse.from(origenService.update(entity)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        origenService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
