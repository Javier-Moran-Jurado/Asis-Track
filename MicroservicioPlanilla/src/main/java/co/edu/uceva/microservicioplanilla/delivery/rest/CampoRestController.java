package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.model.OpcionesCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.IOpcionesCampoRepository;
import co.edu.uceva.microservicioplanilla.domain.service.ICampoService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.CampoRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.CampoResponse;
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
@RequestMapping("/api/v1/planilla-service/campos")
@RequiredArgsConstructor
public class CampoRestController {

    private final ICampoService campoService;
    private final IOpcionesCampoRepository opcionesCampoRepository;

    private CampoResponse toResponse(Campo entity) {
        List<OpcionesCampo> opciones = opcionesCampoRepository.findByCampo_IdOrderByOrden(entity.getId());
        return CampoResponse.from(entity, opciones);
    }

    private List<CampoResponse> toResponseList(List<Campo> entities) {
        return entities.stream().map(this::toResponse).toList();
    }

    @GetMapping
    public ResponseEntity<List<CampoResponse>> findAll() {
        return ResponseEntity.ok(toResponseList(campoService.findAll()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CampoResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(toResponse(campoService.findById(id)));
    }

    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<CampoResponse>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(toResponseList(campoService.findByPlanillaId(planillaId)));
    }

    @PostMapping
    public ResponseEntity<CampoResponse> save(@RequestBody CampoRequest request) {
        Campo saved = campoService.save(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CampoResponse> update(@PathVariable Long id, @RequestBody CampoRequest request) {
        Campo updated = campoService.update(id, request);
        return ResponseEntity.ok(toResponse(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        campoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/batch")
    public ResponseEntity<?> saveAll(@RequestBody @Size(max = 200) List<CampoRequest> requests) {
        try {
            List<CampoResponse> saved = toResponseList(campoService.saveAll(requests));
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("status", 400, "message", e.getMessage()));
        }
    }
}
