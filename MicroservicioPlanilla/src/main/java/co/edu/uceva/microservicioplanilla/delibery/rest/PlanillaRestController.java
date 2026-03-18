package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;

    public PlanillaRestController(IPlanillaService planillaService) {
        this.planillaService = planillaService;
    }

    @GetMapping("/planillas")
    public List<Planilla> getPlanillas() {
        return planillaService.findAll();
    }

    @PostMapping("/planillas")
    public Planilla save(@RequestBody Planilla planilla) {
        return planillaService.save(planilla);
    }

    @DeleteMapping("/planillas")
    public void delete(@RequestBody Planilla planilla) {
        planillaService.delete(planilla);
    }

    @PutMapping("/planillas")
    public Planilla update(@RequestBody Planilla planilla) {
        return planillaService.update(planilla);
    }

    @GetMapping("/planillas/{id}")
    public Planilla findById(@PathVariable Long id) {
        return planillaService.findById(id);
    }
}