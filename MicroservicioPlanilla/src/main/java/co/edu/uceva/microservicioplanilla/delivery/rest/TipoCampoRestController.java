package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.service.ITipoCampoService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.TipoCampoRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.TipoCampoResponse;
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
    public ResponseEntity<List<TipoCampoResponse>> findAll() {
        return ResponseEntity.ok(tipoCampoService.findAll().stream().map(TipoCampoResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TipoCampoResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(TipoCampoResponse.from(tipoCampoService.findById(id)));
    }

    @PostMapping
    public ResponseEntity<TipoCampoResponse> save(@RequestBody TipoCampoRequest request) {
        TipoCampo entity = new TipoCampo();
        entity.setTipo(request.getTipo());
        return ResponseEntity.status(HttpStatus.CREATED).body(TipoCampoResponse.from(tipoCampoService.save(entity)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TipoCampoResponse> update(@PathVariable Long id, @RequestBody TipoCampoRequest request) {
        TipoCampo entity = tipoCampoService.findById(id);
        entity.setTipo(request.getTipo());
        return ResponseEntity.ok(TipoCampoResponse.from(tipoCampoService.update(entity)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        tipoCampoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
