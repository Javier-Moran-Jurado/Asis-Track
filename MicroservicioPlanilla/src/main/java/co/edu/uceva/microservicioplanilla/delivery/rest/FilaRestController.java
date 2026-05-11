package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import co.edu.uceva.microservicioplanilla.domain.service.IFilaService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.FilaRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.FilaResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Validated
@RestController
@RequestMapping("/api/v1/planilla-service/filas")
@RequiredArgsConstructor
public class FilaRestController {

    private final IFilaService filaService;

    @PreAuthorize("hasAnyRole('Administrador', 'Administrativo')")
    @GetMapping
    public ResponseEntity<List<FilaResponse>> findAll() {
        return ResponseEntity.ok(toResponse(filaService.findAll()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<FilaResponse> findById(@PathVariable Long id) {
        return ResponseEntity.ok(toResponse(filaService.findById(id)));
    }

    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<FilaResponse>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(toResponse(filaService.findByPlanillaId(planillaId)));
    }

    @GetMapping("/mis-filas")
    public ResponseEntity<List<FilaResponse>> findMisFilas() {
        Long codigo = getCurrentUserCodigo();
        return ResponseEntity.ok(toResponse(filaService.findByCodigoUsuario(codigo)));
    }

    @PreAuthorize("hasAnyRole('Administrador', 'Administrativo')")
    @GetMapping("/usuario/{codigoUsuario}")
    public ResponseEntity<List<FilaResponse>> findByUsuario(@PathVariable Long codigoUsuario) {
        return ResponseEntity.ok(toResponse(filaService.findByCodigoUsuario(codigoUsuario)));
    }

    @PostMapping
    public ResponseEntity<FilaResponse> create(@RequestBody @Valid FilaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(filaService.create(request)));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/batch")
    public ResponseEntity<?> createBatch(@RequestBody @Size(max = 500) List<FilaRequest> requests) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(filaService.createBatch(requests)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("status", 400, "message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<FilaResponse> updateFull(@PathVariable Long id, @RequestBody @Valid FilaRequest request) {
        return ResponseEntity.ok(toResponse(filaService.updateFull(id, request)));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<FilaResponse> patch(@PathVariable Long id, @RequestBody @Valid FilaRequest request) {
        return ResponseEntity.ok(toResponse(filaService.patch(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        filaService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private Long getCurrentUserCodigo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetails userDetails) {
            return Long.parseLong(userDetails.getUsername());
        }
        return null;
    }

    private List<FilaResponse> toResponse(List<Fila> filas) {
        return filas.stream().map(FilaResponse::from).toList();
    }

    private FilaResponse toResponse(Fila fila) {
        return FilaResponse.from(fila);
    }
}
