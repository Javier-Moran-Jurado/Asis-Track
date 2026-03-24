package co.edu.uceva.microservicioreporte.delibery.rest;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;
import co.edu.uceva.microservicioreporte.domain.service.IReporteService;
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
    public List<Reporte> getAll() {
        return service.findAll();
    }

    @GetMapping("/reportes/{id}")
    public Reporte getById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping("/reportes")
    public Reporte save(@RequestBody Reporte reporte) {
        return service.save(reporte);
    }

    @PutMapping("/reportes")
    public Reporte update(@RequestBody Reporte reporte) {
        return service.update(reporte);
    }

    @DeleteMapping("/reportes/{id}")
    public void delete(@PathVariable Long id) {
        service.deleteById(id);
    }
}