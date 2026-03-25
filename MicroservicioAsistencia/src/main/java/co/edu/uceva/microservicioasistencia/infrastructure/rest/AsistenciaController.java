package co.edu.uceva.microservicioasistencia.infrastructure.rest;

import co.edu.uceva.microservicioasistencia.domain.model.Asistencia;
import co.edu.uceva.microservicioasistencia.domain.service.IAsistenciaService;
import co.edu.uceva.microservicioasistencia.infrastructure.rest.dto.EntradaRequest;
import co.edu.uceva.microservicioasistencia.infrastructure.rest.dto.JustificarRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/asistencias")
@RequiredArgsConstructor
public class AsistenciaController {

    private final IAsistenciaService asistenciaService;
    @PreAuthorize("isAuthenticated() and hasRole('Estudiante')")
    @PostMapping("/entrada")
    public ResponseEntity<Asistencia> registrarEntrada(
            @RequestParam String codigoEstudiante,
            @RequestParam Long planillaId,
            @RequestBody(required = false) EntradaRequest request) {

        String geolocalizacionJson = null;
        String datosAdicionalesJson = null;

        if (request != null) {
            // Convertir objeto Geolocalizacion a String JSON
            if (request.getGeolocalizacion() != null) {
                StringBuilder geoBuilder = new StringBuilder("{");
                geoBuilder.append("\"lat\":").append(request.getGeolocalizacion().getLat());
                geoBuilder.append(",\"lng\":").append(request.getGeolocalizacion().getLng());

                if (request.getGeolocalizacion().getPrecision() != null) {
                    geoBuilder.append(",\"precision\":").append(request.getGeolocalizacion().getPrecision());
                }
                geoBuilder.append("}");
                geolocalizacionJson = geoBuilder.toString();
            }

            // Convertir objeto DatosAdicionales a String JSON
            if (request.getDatosAdicionales() != null) {
                StringBuilder datosBuilder = new StringBuilder("{");
                boolean primero = true;

                if (request.getDatosAdicionales().getDispositivo() != null) {
                    datosBuilder.append("\"dispositivo\":\"").append(request.getDatosAdicionales().getDispositivo()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getAppVersion() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"appVersion\":\"").append(request.getDatosAdicionales().getAppVersion()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getBateria() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"bateria\":").append(request.getDatosAdicionales().getBateria());
                    primero = false;
                }
                if (request.getDatosAdicionales().getRed() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"red\":\"").append(request.getDatosAdicionales().getRed()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getSistema() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"sistema\":\"").append(request.getDatosAdicionales().getSistema()).append("\"");
                }
                datosBuilder.append("}");
                datosAdicionalesJson = datosBuilder.toString();
            }
        }

        return new ResponseEntity<>(
                asistenciaService.registrarEntrada(codigoEstudiante, planillaId, geolocalizacionJson, datosAdicionalesJson),
                HttpStatus.CREATED
        );
    }

    @PreAuthorize("isAuthenticated() and hasRole('Estudiante')")
    @PostMapping("/salida")
    public ResponseEntity<Asistencia> registrarSalida(
            @RequestParam String codigoEstudiante,
            @RequestParam Long planillaId,
            @RequestBody(required = false) EntradaRequest request) {

        String geolocalizacionJson = null;
        String datosAdicionalesJson = null;

        if (request != null) {
            // Convertir objeto Geolocalizacion a String JSON
            if (request.getGeolocalizacion() != null) {
                StringBuilder geoBuilder = new StringBuilder("{");
                geoBuilder.append("\"lat\":").append(request.getGeolocalizacion().getLat());
                geoBuilder.append(",\"lng\":").append(request.getGeolocalizacion().getLng());

                if (request.getGeolocalizacion().getPrecision() != null) {
                    geoBuilder.append(",\"precision\":").append(request.getGeolocalizacion().getPrecision());
                }
                geoBuilder.append("}");
                geolocalizacionJson = geoBuilder.toString();
            }

            // Convertir objeto DatosAdicionales a String JSON
            if (request.getDatosAdicionales() != null) {
                StringBuilder datosBuilder = new StringBuilder("{");
                boolean primero = true;

                if (request.getDatosAdicionales().getDispositivo() != null) {
                    datosBuilder.append("\"dispositivo\":\"").append(request.getDatosAdicionales().getDispositivo()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getAppVersion() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"appVersion\":\"").append(request.getDatosAdicionales().getAppVersion()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getBateria() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"bateria\":").append(request.getDatosAdicionales().getBateria());
                    primero = false;
                }
                if (request.getDatosAdicionales().getRed() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"red\":\"").append(request.getDatosAdicionales().getRed()).append("\"");
                    primero = false;
                }
                if (request.getDatosAdicionales().getSistema() != null) {
                    if (!primero) datosBuilder.append(",");
                    datosBuilder.append("\"sistema\":\"").append(request.getDatosAdicionales().getSistema()).append("\"");
                }
                datosBuilder.append("}");
                datosAdicionalesJson = datosBuilder.toString();
            }
        }

        return new ResponseEntity<>(
                asistenciaService.registrarSalida(codigoEstudiante, planillaId, geolocalizacionJson, datosAdicionalesJson),
                HttpStatus.CREATED
        );
    }

    @PreAuthorize("isAuthenticated() and hasRole('Estudiante')")
    @PostMapping("/justificar")
    public ResponseEntity<Asistencia> justificarAusencia(
            @RequestParam String codigoEstudiante,
            @RequestParam Long planillaId,
            @RequestBody(required = false) JustificarRequest request) {

        String datosAdicionales = request != null ? request.getDatosAdicionales() : null;
        String justificacion = request != null ? request.getJustificacion() : null;

        // Combinar justificación con datos adicionales si existe
        if (justificacion != null) {
            String justificacionJson = "{\"justificacion\":\"" + justificacion + "\"}";
            if (datosAdicionales != null) {
                // Si ya hay datos adicionales, combinamos
                datosAdicionales = justificacionJson.substring(0, justificacionJson.length() - 1) +
                        "," + datosAdicionales.substring(1);
            } else {
                datosAdicionales = justificacionJson;
            }
        }

        return new ResponseEntity<>(
                asistenciaService.justificarAusencia(codigoEstudiante, planillaId, datosAdicionales),
                HttpStatus.CREATED
        );
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo')")
    @GetMapping("/{id}")
    public ResponseEntity<Asistencia> findById(@PathVariable Long id) {
        return ResponseEntity.ok(asistenciaService.findById(id));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Docente', 'Administrador', 'Administrativo')")
    @GetMapping("/estudiante/{codigoEstudiante}")
    public ResponseEntity<List<Asistencia>> findByCodigoEstudiante(@PathVariable String codigoEstudiante) {
        return ResponseEntity.ok(asistenciaService.findByCodigoEstudiante(codigoEstudiante));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @GetMapping("/planilla/{planillaId}")
    public ResponseEntity<List<Asistencia>> findByPlanillaId(@PathVariable Long planillaId) {
        return ResponseEntity.ok(asistenciaService.findByPlanillaId(planillaId));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @GetMapping("/planilla/{planillaId}/presentes")
    public ResponseEntity<List<Asistencia>> findPresentesByPlanilla(@PathVariable Long planillaId) {
        return ResponseEntity.ok(asistenciaService.findPresentesByPlanilla(planillaId));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @GetMapping("/rango")
    public ResponseEntity<List<Asistencia>> findByFechaHoraRegistroBetween(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fin) {
        return ResponseEntity.ok(asistenciaService.findByFechaHoraRegistroBetween(inicio, fin));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @PutMapping("/{id}")
    public ResponseEntity<Asistencia> update(@PathVariable Long id, @RequestBody Asistencia asistencia) {
        asistencia.setId(id);
        return ResponseEntity.ok(asistenciaService.update(asistencia));
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        asistenciaService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    @PatchMapping("/{id}/estado")
    public ResponseEntity<Asistencia> actualizarEstado(
            @PathVariable Long id,
            @RequestParam String estado) {
        return ResponseEntity.ok(asistenciaService.actualizarEstado(id, estado));
    }
}