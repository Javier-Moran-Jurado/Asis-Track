package co.edu.uceva.microserviciojustificacion.infrastructure.config;

import co.edu.uceva.microserviciojustificacion.domain.model.Justificacion;
import co.edu.uceva.microserviciojustificacion.domain.repository.IJustificacionRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IJustificacionRepository justificacionRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public void run(String... args) {
        if (justificacionRepository.count() > 0) {
            logger.info("Datos de prueba de Justificacion ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba de Justificacion con encriptación activa...");

        Object[][] datos = {
            // {registroId, usuarioCodigo, motivo, documentoUrl, estado}
            {1L, "2024117001", "Enfermedad", "https://ejemplo.com/documento1.pdf", "APROBADO"},
            {2L, "2024117002", "Cita médica", "https://ejemplo.com/documento2.pdf", "PENDIENTE"},
            {3L, "2024117003", "Tráfico", null, "RECHAZADO"}
        };

        for (Object[] d : datos) {
            try {
                Justificacion j = new Justificacion();
                j.setRegistroId((Long) d[0]);
                j.setUsuarioCodigo((String) d[1]);
                j.setMotivo((String) d[2]);
                j.setDocumentoUrl((String) d[3]);
                j.setEstado((String) d[4]);
                j.setFechaSolicitud(LocalDateTime.now());
                
                justificacionRepository.save(j);
            } catch (Exception e) {
                logger.error("Error al insertar justificación de prueba: " + e.getMessage());
            }
        }
    }
}
