package co.edu.uceva.microservicioasistencia.infrastructure.config;

import co.edu.uceva.microservicioasistencia.domain.model.Asistencia;
import co.edu.uceva.microservicioasistencia.domain.repository.IAsistenciaRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IAsistenciaRepository asistenciaRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public void run(String... args) {
        if (asistenciaRepository.count() > 0) {
            logger.info("Datos de prueba de Asistencia ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba de Asistencia con encriptación activa...");

        Object[][] datos = {
            // {codigoEstudiante, planillaId, estado, geolocalizacion, datosAdicionales}
            {"2024117001", 1L, "PRESENTE", "{\"lat\": 4.628692, \"lng\": -74.065396, \"precision\": 10}", "{\"dispositivo\": \"Android\", \"appVersion\": \"1.0.0\"}"},
            {"2024117002", 1L, "PRESENTE", "{\"lat\": 4.628700, \"lng\": -74.065400, \"precision\": 8}", "{\"dispositivo\": \"iOS\", \"appVersion\": \"1.0.0\"}"},
            {"2024117003", 1L, "AUSENTE", null, "{\"justificacion\": \"Enfermedad\"}"},
            {"2024117004", 1L, "TARDANZA", "{\"lat\": 4.628800, \"lng\": -74.065500, \"precision\": 15}", "{\"dispositivo\": \"Android\", \"appVersion\": \"1.0.0\", \"motivo\": \"Tráfico\"}"},
            {"2024117005", 2L, "PRESENTE", "{\"lat\": 4.628900, \"lng\": -74.065600, \"precision\": 12}", "{\"dispositivo\": \"iPhone\", \"appVersion\": \"1.0.1\"}"}
        };

        for (Object[] d : datos) {
            try {
                Asistencia a = new Asistencia();
                a.setCodigoEstudiante((String) d[0]);
                a.setPlanillaId((Long) d[1]);
                a.setEstado((String) d[2]);
                a.setGeolocalizacion((String) d[3]);
                a.setDatosAdicionales((String) d[4]);
                a.setFechaHoraRegistro(LocalDateTime.now());
                
                asistenciaRepository.save(a);
            } catch (Exception e) {
                logger.error("Error al insertar asistencia de prueba: " + e.getMessage());
            }
        }
    }
}
