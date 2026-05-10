package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.ai.CompositeAiService;
import co.edu.uceva.microservicioplanilla.domain.service.GeneradorPlanillaService;
import co.edu.uceva.microservicioplanilla.domain.service.ICampoService;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import co.edu.uceva.microservicioplanilla.service.PlanillaProcessingService;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.*;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import jakarta.validation.Valid;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.List;
import lombok.SneakyThrows;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

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

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador')"
    )
    @GetMapping("/planillas")
    public List<Planilla> getPlanillas() {
        return planillaService.findAll();
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')"
    )
    @PostMapping("/planillas")
    public Planilla save(@RequestBody Planilla planilla) {
        return planillaService.save(planilla);
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/digitalizar")
    public List<PlanillaDigitalizadaResponse> digitalizar(
            @RequestParam("file") MultipartFile file,
            @RequestParam("estructuraJson") String estructuraJson) {
        try {
            return planillaProcessingService.processAndUpload(file, estructuraJson);
        } catch (IllegalArgumentException ie) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ie.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error en digitalizar: " + e.getMessage());
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/digitalizar/guardar")
    public List<PlanillaDigitalizadaResponse> guardarDigitalizacion(@RequestBody List<PlanillaDigitalizadaResponse> datos) {
        try {
            return planillaProcessingService.saveCorrectedData(datos);
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            e.printStackTrace();
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error en el servidor: " + e.getMessage());
        }
    }

    public static class RecorteRequest {
        public int index;
        public int x;
        public int y;
        public int w;
        public int h;
        public String sourceImageB64;
    }

    public static class RecorteResponse {
        public int index;
        public String firmaB64;
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/digitalizar/recortar")
    public RecorteResponse corregirRecorteFirma(
        @RequestBody RecorteRequest request
    ) {
        try {
            Path tmpDir = Files.createTempDirectory("custom-crop");
            String path = PythonSignatureUtil.cropSignature(
                request.sourceImageB64,
                request.x,
                request.y,
                request.w,
                request.h,
                tmpDir
            );
            byte[] fileBytes = Files.readAllBytes(Paths.get(path));
            String base64 =
                "data:image/png;base64," +
                Base64.getEncoder().encodeToString(fileBytes);

            Files.walk(tmpDir)
                .sorted(java.util.Comparator.reverseOrder())
                .map(Path::toFile)
                .forEach(java.io.File::delete);

            RecorteResponse response = new RecorteResponse();
            response.index = request.index;
            response.firmaB64 = base64;
            return response;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error recortando firma: " + e.getMessage());
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/campos")
    public String obtenerCampos(@RequestParam("file") MultipartFile file) {
        try {
            String text = "";
            String contentType = file.getContentType();
            
            if ("application/pdf".equals(contentType)) {
                List<Resource> resources = FileHandlerUtil.pdfToImages(file);
                text = compositeAiService.processStructureBatch(resources);
            } else if ("application/zip".equals(contentType) || "application/x-zip-compressed".equals(contentType)) {
                List<Resource> resources = FileHandlerUtil.extractZip(file);
                text = compositeAiService.processStructureBatch(resources);
            } else if (contentType != null && contentType.startsWith("image/")) {
                text = compositeAiService.processStructureBatch(
                    List.of(file.getResource())
                );
            } else {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tipo de archivo no soportado: " + contentType);
            }
            return text;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error en obtenerCampos: " + e.getMessage());
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')"
    )
    @DeleteMapping("/planillas/{id}")
    public void delete(@PathVariable Long id) {
        planillaService.deleteById(id);
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')"
    )
    @PutMapping("/planillas")
    public Planilla update(@RequestBody Planilla planilla) {
        return planillaService.update(planilla);
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Docente', 'Monitor', 'Decano')"
    )
    @GetMapping("/planillas/{id}")
    public Planilla findById(@PathVariable Long id) {
        return planillaService.findById(id);
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/{planillaId}/proponer-estructura")
    public EstructuraPropuestaResponse proponerEstructura(
            @PathVariable Long planillaId,
            @RequestParam("imagen") MultipartFile imagen) {
        try {
            return planillaProcessingService.proposeStructureFromImage(planillaId, imagen);
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error proponiendo estructura: " + e.getMessage());
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/{planillaId}/confirmar-estructura")
    public List<co.edu.uceva.microservicioplanilla.domain.model.Campo> confirmarEstructura(
            @PathVariable Long planillaId,
            @Valid @RequestBody List<CampoRequest> campos) {
        for (CampoRequest cr : campos) {
            cr.setPlanillaId(planillaId);
        }
        return campoService.saveAll(campos);
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/generar-propuesta")
    public PlanillaPropuestaResponse generarPropuesta(@Valid @RequestBody GenerarPropuestaRequest request) {
        try {
            return generadorPlanillaService.generarPropuesta(request);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error generando propuesta: " + e.getMessage());
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/generar-propuesta/confirmar")
    public Planilla confirmarPropuesta(@Valid @RequestBody ConfirmarPropuestaRequest request) {
        try {
            return generadorPlanillaService.confirmarPropuesta(request);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error confirmando propuesta: " + e.getMessage());
        }
    }
}
