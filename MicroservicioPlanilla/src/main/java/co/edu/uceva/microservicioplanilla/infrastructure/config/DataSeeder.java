package co.edu.uceva.microservicioplanilla.infrastructure.config;

import co.edu.uceva.microservicioplanilla.domain.model.Asistencia;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.repository.IAsistenciaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Random;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IPlanillaRepository planillaRepository;
    private final IAsistenciaRepository asistenciaRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());
    private final Random random = new Random();

    @Override
    public void run(String... args) {
        if (planillaRepository.count() > 0) {
            logger.info("Datos de prueba de Planilla ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba de Planilla con estadísticas...");

        String estructuraEncuesta = """
            {"encabezados":[
                {"nombre":"Cédula","tipo_campo":"numerico","opciones":[]},
                {"nombre":"Nombres","tipo_campo":"texto","opciones":[]},
                {"nombre":"Apellidos","tipo_campo":"texto","opciones":[]},
                {"nombre":"Programa","tipo_campo":"desplegable","opciones":["Ing.Sistemas","Ing.Industrial","Ing.Electronica","Arquitectura"]},
                {"nombre":"Modalidad","tipo_campo":"radio","opciones":["Presencial","Virtual"]},
                {"nombre":"AceptaTerminos","tipo_campo":"checkbox","opciones":["Sí","No"]},
                {"nombre":"Edad","tipo_campo":"numerico","opciones":[]},
                {"nombre":"FechaNacimiento","tipo_campo":"fecha","opciones":[]}
            ]}
            """;

        Planilla planilla = new Planilla();
        planilla.setLugar("Auditorio Principal");
        planilla.setMetadatos("Encuesta de Satisfaction");
        planilla.setEstructuraMetadata(estructuraEncuesta);
        planilla.setFechaHoraInicio(LocalDateTime.now().plusHours(1));
        planilla.setFechaHoraFin(LocalDateTime.now().plusHours(3));
        planilla.setFechaCreacion(LocalDateTime.now());
        planilla = planillaRepository.save(planilla);
        Long planillaId = planilla.getId();

        String[] nombres = {"Juan", "Maria", "Pedro", "Ana", "Luis", "Carlos", "Laura", "Sofia", "Miguel", "Isabel"};
        String[] apellidos = {"Garcia", "Rodriguez", "Martinez", "Lopez", "Gonzalez", "Perez", "Sanchez", "Torres", "Rivera", "Diaz"};
        String[] programas = {"Ing.Sistemas", "Ing.Industrial", "Ing.Electronica", "Arquitectura"};
        String[] modalidades = {"Presencial", "Virtual"};
        String[] acepta = {"Sí", "No"};

        for (int i = 0; i < 30; i++) {
            try {
                String numDoc = String.valueOf(10000000 + random.nextInt(90000000));
                String nombre = nombres[random.nextInt(nombres.length)];
                String apellido = apellidos[random.nextInt(apellidos.length)];
                String programa = programas[random.nextInt(programas.length)];
                String modalidad = modalidades[random.nextInt(modalidades.length)];
                String aceptaTerminos = acepta[random.nextInt(acepta.length)];
                int edad = 17 + random.nextInt(25);
                String fechaNac = (1990 + random.nextInt(15)) + "-0" + (1 + random.nextInt(9)) + "-15";

                String datosJson = String.format(
                    "{\"Cédula\":\"%s\",\"Nombres\":\"%s\",\"Apellidos\":\"%s\",\"Programa\":\"%s\",\"Modalidad\":\"%s\",\"AceptaTerminos\":\"%s\",\"Edad\":\"%d\",\"FechaNacimiento\":\"%s\"}",
                    numDoc, nombre, apellido, programa, modalidad, aceptaTerminos, edad, fechaNac
                );

                Asistencia a = new Asistencia();
                a.setCodigoEstudiante("E" + (1000 + i));
                a.setPlanillaId(planillaId);
                a.setFechaHoraRegistro(LocalDateTime.now().minusMinutes(random.nextInt(120)));
                a.setEstado("PRESENTE");
                a.setGeolocalizacion("{\"lat\":4.0,\"lng\":-72.0}");
                a.setDatosAdicionales(datosJson);

                asistenciaRepository.save(a);
            } catch (Exception e) {
                logger.error("Error al insertar asistencia: " + e.getMessage());
            }
        }

        logger.info("Seed completado: 1 planilla + 30 asistencias con datos dinámicos.");
    }
}
