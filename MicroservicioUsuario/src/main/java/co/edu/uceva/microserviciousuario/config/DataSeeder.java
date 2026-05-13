package co.edu.uceva.microserviciousuario.config;

import co.edu.uceva.microserviciousuario.domain.model.Rol;
import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IRolRepository;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class DataSeeder implements ApplicationRunner {

    private final IUsuarioRepository usuarioRepository;
    private final IRolRepository rolRepository;
    private final Logger logger = LoggerFactory.getLogger(getClass());

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (usuarioRepository.count() > 0) {
            logger.info("Datos de prueba ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba con encriptación activa...");

        // Paso 1: Crear roles
        String[] nombresRoles = {
            "Estudiante", "Coordinador", "Docente", "Administrativo",
            "Decano", "Rector", "Administrador", "Monitor", "Directivo"
        };
        Map<String, Rol> roles = new LinkedHashMap<>();
        for (String nombre : nombresRoles) {
            Rol rol = rolRepository.save(new Rol(nombre));
            roles.put(nombre, rol);
            logger.info("Rol '{}' creado con id {}.", nombre, rol.getId());
        }

        // Paso 2: Crear usuarios (referencian roles)
        Object[][] datos = {
            // {codigo, nombre, correo, contrasena, cedula, telefono, rolNombre}
            {1L, "Juan Perez", "juan.perez@uceva.edu.co", "Segura#123", 1001234567L, 3101234567L, "Monitor"},
            {2L, "Maria Lopez", "maria.lopez@uceva.edu.co", "Clave$456", 1009876543L, 3209876543L, "Estudiante"},
            {3L, "Carlos Gomez", "carlos.gomez@uceva.edu.co", "Pass&789a", 1005551234L, 3155551234L, "Docente"},
            {4L, "Admin Sistema", "admin@uceva.edu.co", "Admin#2024", 1000000001L, 3000000001L, "Administrador"},
            {5L, "Laura Martinez", "laura.martinez@uceva.edu.co", "Coord!567", 1002223344L, 3122223344L, "Coordinador"},
            {6L, "Pedro Ruiz", "pedro.ruiz@uceva.edu.co", "Decano#11", 1003334455L, 3133334455L, "Decano"},
            {7L, "Ana Torres", "ana.torres@uceva.edu.co", "Docen$789", 1004445566L, 3144445566L, "Docente"},
            {8L, "Luis Vargas", "luis.vargas@uceva.edu.co", "Decan!999", 1005556677L, 3155556677L, "Decano"},
            {9L, "Sofia Castro", "sofia.castro@uceva.edu.co", "Coord*321", 1006667788L, 3166667788L, "Coordinador"},
            {10L, "Diego Herrera", "diego.herrera@uceva.edu.co", "Coord_654", 1007778899L, 3177778899L, "Coordinador"},
            {230231022L, "Andres David Guevara Martinez", "andres.guevara03@uceva.edu.co", "123456789_Xd", 1234567890L, 3001234567L, "Administrador"},
        };

        for (Object[] d : datos) {
            try {
                Usuario u = new Usuario();
                u.setCodigo((Long) d[0]);
                u.setNombreCompleto((String) d[1]);
                u.setCorreo((String) d[2]);
                u.setContrasena((String) d[3]);
                u.setCedula((Long) d[4]);
                u.setTelefono((Long) d[5]);
                u.setRol(roles.get((String) d[6]));
                usuarioRepository.save(u);
                logger.info("Usuario {} insertado y encriptado correctamente.", d[1]);
            } catch (Exception e) {
                logger.error("Error insertando usuario {}: {}", d[1], e.getMessage());
            }
        }

        logger.info("Seed completado. {} roles + {} usuarios insertados.", roles.size(), usuarioRepository.count());
    }
}
