package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;
import co.edu.uceva.microservicioplanilla.domain.service.ILugarService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.LugarRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.LugarResponse;
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
    public ResponseEntity<List<LugarResponse>> findAll() {
        return ResponseEntity.ok(lugarService.findAll().stream().map(LugarResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<LugarResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(LugarResponse.from(lugarService.findById(id)));
    }

    @PostMapping
    public ResponseEntity<LugarResponse> save(@RequestBody LugarRequest request) {
        Lugar entity = new Lugar();
        entity.setNombre(request.getNombre());
        entity.setCoordenadas(request.getCoordenadas());
        return ResponseEntity.status(HttpStatus.CREATED).body(LugarResponse.from(lugarService.save(entity)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<LugarResponse> update(@PathVariable Long id, @RequestBody LugarRequest request) {
        Lugar entity = lugarService.findById(id);
        entity.setNombre(request.getNombre());
        entity.setCoordenadas(request.getCoordenadas());
        return ResponseEntity.ok(LugarResponse.from(lugarService.update(entity)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        lugarService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
