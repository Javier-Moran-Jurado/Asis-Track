package co.edu.uceva.microservicioreporte.delibery.rest;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;
import co.edu.uceva.microservicioreporte.domain.service.IReporteService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/reporte-service")
public class ReporteRestController {

    private final IReporteService service;

    public ReporteRestController(IReporteService service) {
        this.service = service;
    }

    @GetMapping("/reportes")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador')")
    public List<Reporte> getAll() {
        return service.findAll();
    }

    @GetMapping("/reportes/{id}")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    public Reporte getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping("/reportes")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    public Reporte save(@RequestBody Reporte reporte) {
        return service.save(reporte);
    }

    @PutMapping("/reportes")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    public Reporte update(@RequestBody Reporte reporte) {
        return service.update(reporte);
    }

    @DeleteMapping("/reportes/{id}")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    public void delete(@PathVariable Long id) {
        service.deleteById(id);
    }
}