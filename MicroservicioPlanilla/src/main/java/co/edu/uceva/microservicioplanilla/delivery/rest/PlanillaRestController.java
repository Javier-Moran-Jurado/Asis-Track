package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.service.CompositeAiService;
import co.edu.uceva.microservicioplanilla.domain.service.IPlanillaService;
import co.edu.uceva.microservicioplanilla.service.PlanillaProcessingService;
import co.edu.uceva.microservicioplanilla.utils.FileHandlerUtil;
import co.edu.uceva.microservicioplanilla.utils.PythonSignatureUtil;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.List;
import lombok.SneakyThrows;
import org.springframework.core.io.Resource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/planilla-service")
public class PlanillaRestController {

    private final IPlanillaService planillaService;
    private final CompositeAiService compositeAiService;
    private final PlanillaProcessingService planillaProcessingService;

    public PlanillaRestController(
        IPlanillaService planillaService,
        CompositeAiService compositeAiService,
        PlanillaProcessingService planillaProcessingService
    ) {
        this.planillaService = planillaService;
        this.compositeAiService = compositeAiService;
        this.planillaProcessingService = planillaProcessingService;
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
    public String digitalizar(@RequestParam("file") MultipartFile file) {
        try {
            // Retorna los datos y las imagenes en Base64 temporalmente
            return planillaProcessingService.processAndUpload(file);
        } catch (Exception e) {
            System.err.println("[!] Error en digitalizar: " + e.getMessage());
            e.printStackTrace();
            return "Error en el servidor: " + e.getMessage();
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/digitalizar/guardar")
    public String guardarDigitalizacion(@RequestBody String jsonData) {
        try {
            // Recibe los datos corregidos (o tal cual), guarda las imagenes en S3 y retorna los enlaces
            return planillaProcessingService.saveCorrectedData(jsonData);
        } catch (Exception e) {
            System.err.println(
                "[!] Error en guardar digitalizacion: " + e.getMessage()
            );
            e.printStackTrace();
            return "Error en el servidor: " + e.getMessage();
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

            // Limpieza
            Files.walk(tmpDir)
                .sorted(java.util.Comparator.reverseOrder())
                .map(Path::toFile)
                .forEach(java.io.File::delete);

            RecorteResponse response = new RecorteResponse();
            response.index = request.index;
            response.firmaB64 = base64;
            return response;
        } catch (Exception e) {
            System.err.println(
                "[!] Error en corregirRecorteFirma: " + e.getMessage()
            );
            e.printStackTrace();
            throw new RuntimeException(
                "Error recortando firma: " + e.getMessage()
            );
        }
    }

    @PreAuthorize(
        "isAuthenticated() and hasAnyRole('Administrativo', 'Administrador', 'Monitor')"
    )
    @PostMapping("/planillas/campos")
    public String obtenerCampos(@RequestParam("file") MultipartFile file) {
        try {
            String text = "";
            System.out.println(
                "[*] Obtener Campos - Tipo de contenido: " +
                    file.getContentType()
            );
            if (file.getContentType().equals("application/pdf")) {
                List<Resource> resources = FileHandlerUtil.pdfToImages(file);
                text = compositeAiService.processStructureBatch(resources);
            } else if (file.getContentType().equals("application/zip")) {
                List<Resource> resources = FileHandlerUtil.extractZip(file);
                text = compositeAiService.processStructureBatch(resources);
            } else if (file.getContentType().equals("image/jpeg")) {
                text = compositeAiService.processStructureBatch(
                    List.of(file.getResource())
                );
            } else {
                return (
                    "Error: Tipo de archivo no soportado: " +
                    file.getContentType()
                );
            }
            return text;
        } catch (Exception e) {
            System.err.println("[!] Error en obtenerCampos: " + e.getMessage());
            e.printStackTrace();
            return "Error en el servidor: " + e.getMessage();
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
}
