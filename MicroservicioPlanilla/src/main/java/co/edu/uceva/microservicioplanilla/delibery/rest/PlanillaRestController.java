package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;

    public PlanillaRestController(IPlanillaService planillaService) {
        this.planillaService = planillaService;
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador')")
    @GetMapping("/planillas")
    public List<Planilla> getPlanillas() {
        return planillaService.findAll();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @PostMapping("/planillas")
    public Planilla save(@RequestBody Planilla planilla) {
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