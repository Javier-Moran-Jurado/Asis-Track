package co.edu.uceva.microservicioplanilla.delibery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import co.edu.uceva.microservicioplanilla.domain.service.OllamaAiService;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import lombok.SneakyThrows;
import org.springframework.core.io.Resource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;
    private final OllamaAiService ollamaAiService;

    public PlanillaRestController(IPlanillaService planillaService, OllamaAiService ollamaAiService) {
        this.planillaService = planillaService;
        this.ollamaAiService = ollamaAiService;
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

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/digitalizar")
    public String digitalizar(@RequestParam("file") MultipartFile file) {
        try {
            String text = "";
            System.out.println("[*] Digitalizar - Tipo de contenido: " + file.getContentType());
            if (file.getContentType().equals("application/pdf")) {
                List<Resource> resources = FileHandlerUtil.pdfToImages(file);
                text = ollamaAiService.generateResponse(resources);
            } else if (file.getContentType().equals("application/zip")) {
                List<Resource> resources = FileHandlerUtil.extractZip(file);
                text = ollamaAiService.generateResponse(resources);
            } else if (file.getContentType().equals("image/jpeg")) {
                text = ollamaAiService.generateResponse(List.of(file.getResource()));
            } else {
                return "Error: Tipo de archivo no soportado: " + file.getContentType();
            }
            return text;
        } catch (Exception e) {
            System.err.println("[!] Error en digitalizar: " + e.getMessage());
            e.printStackTrace();
            return "Error en el servidor: " + e.getMessage();
        }
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