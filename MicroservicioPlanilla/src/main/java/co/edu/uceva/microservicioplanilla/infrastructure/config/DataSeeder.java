package co.edu.uceva.microservicioplanilla.infrastructure.config;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IPlanillaRepository planillaRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public void run(String... args) {
        if (planillaRepository.count() > 0) {
            logger.info("Datos de prueba de Planilla ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba de Planilla con encriptación activa...");

        Object[][] datos = {
            // {lugar, metadatos}
            {"Sala 101", "Reunión de planificación"},
            {"Auditorio Principal", "Conferencia de tecnología"}
        };

        for (Object[] d : datos) {
            try {
                Planilla p = new Planilla();
                p.setLugar((String) d[0]);
                p.setMetadatos((String) d[1]);
                p.setFechaHoraInicio(LocalDateTime.now().plusHours(1));
                p.setFechaHoraFin(LocalDateTime.now().plusHours(3));
                p.setFechaCreacion(LocalDateTime.now());
                
                planillaRepository.save(p);
            } catch (Exception e) {
                logger.error("Error al insertar planilla de prueba: " + e.getMessage());
            }
        }
    }
}
