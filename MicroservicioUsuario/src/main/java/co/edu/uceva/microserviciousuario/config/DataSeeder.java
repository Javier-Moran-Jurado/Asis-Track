package co.edu.uceva.microserviciousuario.config;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataSeeder implements ApplicationRunner {

    private final IUsuarioRepository usuarioRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (usuarioRepository.count() > 0) {
            logger.info("Datos de prueba ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba con encriptación activa...");

        String[][] datos = {
            // {codigo, nombre, correo, contrasena, cedula, telefono, rol}
            {"1", "Juan Perez", "juan.perez@uceva.edu.co", "Segura#123", "1001234567", "3101234567", "Monitor"},
            {"2", "Maria Lopez", "maria.lopez@uceva.edu.co", "Clave$456", "1009876543", "3209876543", "Estudiante"},
            {"3", "Carlos Gomez", "carlos.gomez@uceva.edu.co", "Pass&789a", "1005551234", "3155551234", "Docente"},
            {"4", "Admin Sistema", "admin@uceva.edu.co", "Admin#2024", "1000000001", "3000000001", "Administrador"},
            {"5", "Laura Martinez", "laura.martinez@uceva.edu.co", "Coord!567", "1002223344", "3122223344", "Coordinador"},
            {"6", "Pedro Ruiz", "pedro.ruiz@uceva.edu.co", "Decano#11", "1003334455", "3133334455", "Decano"},
            {"7", "Ana Torres", "ana.torres@uceva.edu.co", "Docen$789", "1004445566", "3144445566", "Docente"},
            {"8", "Luis Vargas", "luis.vargas@uceva.edu.co", "Decan!999", "1005556677", "3155556677", "Decano"},
            {"9", "Sofia Castro", "sofia.castro@uceva.edu.co", "Coord*321", "1006667788", "3166667788", "Coordinador"},
            {"10", "Diego Herrera", "diego.herrera@uceva.edu.co", "Coord_654", "1007778899", "3177778899", "Coordinador"},
        };

        for (String[] d : datos) {
            try {
                Usuario u = new Usuario();
                u.setCodigo(Long.parseLong(d[0]));
                u.setNombreCompleto(d[1]);
                u.setCorreo(d[2]);
                u.setContrasena(d[3]);
                u.setCedula(Long.parseLong(d[4]));
                u.setTelefono(Long.parseLong(d[5]));
                u.setRol(d[6]);
                usuarioRepository.save(u);
                logger.info("Usuario {} insertado y encriptado correctamente.", d[1]);
            } catch (Exception e) {
                logger.error("Error insertando usuario {}: {}", d[1], e.getMessage());
            }
        }

        logger.info("Seed completado. {} usuarios insertados.", usuarioRepository.count());
    }
}
