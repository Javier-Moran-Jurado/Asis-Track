package co.edu.uceva.microservicioreporte.infrastructure.config;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;
import co.edu.uceva.microservicioreporte.domain.repository.IReporteRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IReporteRepository reporteRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    public void run(String... args) {
        if (reporteRepository.count() > 0) {
            logger.info("Datos de prueba de Reporte ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba de Reporte con encriptación activa...");

        String[][] datos = {
            // {tipo, datos, formato}
            {"PDF", "Reporte ventas", "A4"},
            {"EXCEL", "Reporte usuarios", "XLSX"}
        };

        for (String[] d : datos) {
            try {
                Reporte r = new Reporte();
                r.setTipo(d[0]);
                r.setDatos(d[1]);
                r.setFormato(d[2]);
                
                reporteRepository.save(r);
            } catch (Exception e) {
                logger.error("Error al insertar reporte de prueba: " + e.getMessage());
            }
        }
    }
}
