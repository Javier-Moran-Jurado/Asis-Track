package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import co.edu.uceva.microservicioplanilla.domain.service.HomomorphicEncryptionService;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;
    private final HomomorphicEncryptionService homomorphicEncryptionService;

    public PlanillaRestController(IPlanillaService planillaService, HomomorphicEncryptionService homomorphicEncryptionService) {
        this.planillaService = planillaService;
        this.homomorphicEncryptionService = homomorphicEncryptionService;
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador')")
    @GetMapping("/planillas")
    public List<Planilla> getPlanillas() {
        return planillaService.findAll();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @PostMapping("/planillas")
    public Planilla save(@RequestBody Planilla planilla) {
        if (planilla.getMetadatos() != null && !planilla.getMetadatos().trim().isEmpty()) {
            var encryptionResult = homomorphicEncryptionService.encrypt(planilla.getMetadatos().getBytes(StandardCharsets.UTF_8));
            String ciphertextB64 = Base64.getEncoder().encodeToString(encryptionResult.getCiphertext());
            String keyB64 = Base64.getEncoder().encodeToString(encryptionResult.getKey());
            // Store as <ciphertext_base64>:<key_base64>
            planilla.setMetadatos(ciphertextB64 + ":" + keyB64);
        }
        return planillaService.save(planilla);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @DeleteMapping("/planillas/{id}")
    public void delete(@PathVariable Long id) {
        planillaService.deleteById(id);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @PutMapping("/planillas")
    public Planilla update(@RequestBody Planilla planilla) {
        return planillaService.update(planilla);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @GetMapping("/planillas/{id}")
    public Planilla findById(@PathVariable Long id) {
        return planillaService.findById(id);
    }
}