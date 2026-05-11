package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import co.edu.uceva.microservicioplanilla.domain.service.GeneradorPlanillaService;
import co.edu.uceva.microservicioplanilla.domain.service.ICampoService;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import co.edu.uceva.microservicioplanilla.service.PlanillaProcessingService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import jakarta.validation.Valid;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;
    private final CompositeAiService compositeAiService;
    private final PlanillaProcessingService planillaProcessingService;
    private final GeneradorPlanillaService generadorPlanillaService;
    private final ICampoService campoService;

    public PlanillaRestController(
        IPlanillaService planillaService,
        CompositeAiService compositeAiService,
        PlanillaProcessingService planillaProcessingService,
        GeneradorPlanillaService generadorPlanillaService,
        ICampoService campoService
    ) {
        this.planillaService = planillaService;
        this.compositeAiService = compositeAiService;
        this.planillaProcessingService = planillaProcessingService;
        this.generadorPlanillaService = generadorPlanillaService;
        this.campoService = campoService;
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador')")
    @GetMapping("/planillas")
    public List<PlanillaResponse> getPlanillas() {
        return planillaService.findAll().stream().map(PlanillaResponse::from).toList();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @PostMapping("/planillas")
    public PlanillaResponse save(@Valid @RequestBody PlanillaRequest request) {
        Planilla planilla = planillaService.save(request);
        return PlanillaResponse.from(planilla);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @GetMapping("/planillas/{id}")
    public PlanillaResponse findById(@PathVariable Long id) {
        return PlanillaResponse.from(planillaService.findById(id));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @PutMapping("/planillas/{id}")
    public PlanillaResponse update(@PathVariable Long id, @Valid @RequestBody PlanillaRequest request) {
        return PlanillaResponse.from(planillaService.update(id, request));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')")
    @DeleteMapping("/planillas/{id}")
    public void delete(@PathVariable Long id) {
        planillaService.deleteById(id);
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/digitalizar")
    public PlanillaResponse digitalizar(
            @RequestParam("file") MultipartFile file,
            @RequestParam("planillaId") Long planillaId,
            @RequestParam("estructuraJson") String estructuraJson) {
        try {
            return planillaProcessingService.digitalizarYGuardar(file, planillaId, estructuraJson);
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error en digitalizar: " + e.getMessage());
        }
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/campos")
    public String obtenerCampos(@RequestParam("file") MultipartFile file) {
        try {
            String contentType = file.getContentType();
            if ("application/pdf".equals(contentType)) {
                List<Resource> resources = FileHandlerUtil.pdfToImages(file);
                return compositeAiService.processStructureBatch(resources);
            } else if ("application/zip".equals(contentType) || "application/x-zip-compressed".equals(contentType)) {
                List<Resource> resources = FileHandlerUtil.extractZip(file);
                return compositeAiService.processStructureBatch(resources);
            } else if (contentType != null && contentType.startsWith("image/")) {
                return compositeAiService.processStructureBatch(List.of(file.getResource()));
            } else {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tipo de archivo no soportado: " + contentType);
            }
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error en obtenerCampos: " + e.getMessage());
        }
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/{planillaId}/proponer-estructura")
    public List<CampoResponse> proponerEstructura(
            @PathVariable Long planillaId,
            @RequestParam("imagen") MultipartFile imagen) {
        try {
            return planillaProcessingService.proposeAndSaveStructure(planillaId, imagen);
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error proponiendo estructura: " + e.getMessage());
        }
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/{planillaId}/confirmar-estructura")
    public List<CampoResponse> confirmarEstructura(
            @PathVariable Long planillaId,
            @Valid @RequestBody List<CampoRequest> campos) {
        for (CampoRequest cr : campos) {
            cr.setPlanillaId(planillaId);
        }
        return campoService.saveAll(campos).stream().map(CampoResponse::from).toList();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')")
    @PostMapping("/planillas/generar-propuesta")
    public PlanillaResponse generarPropuesta(
            @RequestParam("descripcion") String descripcion,
            @RequestParam(value = "lugarId", required = false) Long lugarId) {
        try {
            return generadorPlanillaService.generarYGuardarPropuesta(descripcion, lugarId);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error generando propuesta: " + e.getMessage());
        }
    }
}
