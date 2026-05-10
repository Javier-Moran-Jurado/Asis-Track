package co.edu.uceva.microservicioplanilla.infrastructure.config;

import co.edu.uceva.microservicioplanilla.domain.model.*;
import co.edu.uceva.microservicioplanilla.domain.repository.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final IPlanillaRepository planillaRepository;
    private final ITipoCampoRepository tipoCampoRepository;
    private final ILugarRepository lugarRepository;
    private final IOrigenRepository origenRepository;
    private final IEventoRepository eventoRepository;
    private final ICampoRepository campoRepository;
    private final IDatoRepository datoRepository;

    private final Logger logger = LoggerFactory.getLogger(getClass());
    private final Random random = new Random();

    @Override
    public void run(String... args) {
        if (planillaRepository.count() > 0) {
            logger.info("Datos de prueba ya existen, omitiendo seed.");
            return;
        }

        logger.info("Insertando datos de prueba...");

        // Paso 1: Tipos de campo (valores correctos del ER)
        List<String> tipos = List.of(
            "text", "numeric", "signature_file", "file", "date",
            "checkbox", "multivaluecheckbox", "combo", "radio", "e-mail", "secret"
        );
        List<TipoCampo> tiposCampo = tipos.stream().map(t -> {
            TipoCampo tc = new TipoCampo();
            tc.setTipo(t);
            return tipoCampoRepository.save(tc);
        }).toList();

        // Paso 2: Orígenes (digital / digitized)
        Origen origenDigital = new Origen();
        origenDigital.setOrigen("digital");
        origenDigital = origenRepository.save(origenDigital);

        Origen origenDigitized = new Origen();
        origenDigitized.setOrigen("digitized");
        origenRepository.save(origenDigitized);

        // Paso 3: Lugar
        Lugar lugar = new Lugar();
        lugar.setNombre("Auditorio Principal");
        lugar.setCoordenadas("4.0,-72.0");
        lugar = lugarRepository.save(lugar);

        // Paso 4: Evento
        Evento evento = new Evento();
        evento.setLugar(lugar);
        evento.setCodigoUsuario(1L);
        evento.setNombre("Evento de prueba");
        evento.setDescripcion("Evento generado por DataSeeder");
        evento.setFechaCreacion(LocalDateTime.now());
        evento.setFechaHoraInicio(LocalDateTime.now().plusHours(1));
        evento.setFechaHoraFin(LocalDateTime.now().plusHours(3));
        evento = eventoRepository.save(evento);

        // Paso 5: Planilla
        Planilla planilla = new Planilla();
        planilla.setOrigen(origenDigital);
        planilla.setEvento(evento);
        planilla.setUrlReferencia("https://storage.example.com/planillas/prueba.jpg");
        // legacy
        planilla.setLugar("Auditorio Principal");
        planilla.setMetadatos("Encuesta de prueba");
        planilla.setEstructuraMetadata("{\"encabezados\":[{\"nombre\":\"Cédula\",\"tipo_campo\":\"numeric\"},{\"nombre\":\"Nombres\",\"tipo_campo\":\"text\"},{\"nombre\":\"Apellidos\",\"tipo_campo\":\"text\"}]}");
        planilla.setFechaHoraInicio(evento.getFechaHoraInicio());
        planilla.setFechaHoraFin(evento.getFechaHoraFin());
        planilla.setFechaCreacion(LocalDateTime.now());
        planilla = planillaRepository.save(planilla);

        // Paso 6: Campos de la planilla
        TipoCampo tipoNumeric = tiposCampo.stream().filter(t -> "numeric".equals(t.getTipo())).findFirst().orElseThrow();
        TipoCampo tipoText = tiposCampo.stream().filter(t -> "text".equals(t.getTipo())).findFirst().orElseThrow();

        String[] nombresCampos = {"Cédula", "Nombres", "Apellidos"};
        TipoCampo[] tiposPorCampo = {tipoNumeric, tipoText, tipoText};
        Campo[] campos = new Campo[nombresCampos.length];
        for (int i = 0; i < nombresCampos.length; i++) {
            Campo campo = new Campo();
            campo.setPlanilla(planilla);
            campo.setTipoCampo(tiposPorCampo[i]);
            campo.setNombreCampo(nombresCampos[i]);
            campos[i] = campoRepository.save(campo);
        }

        // Paso 7: Datos (30 filas)
        String[] nombres = {"Juan", "Maria", "Pedro", "Ana", "Luis"};
        String[] apellidos = {"Garcia", "Rodriguez", "Martinez", "Lopez", "Gonzalez"};

        for (int i = 0; i < 30; i++) {
            try {
                String numDoc = String.valueOf(10000000 + random.nextInt(90000000));
                String nombre = nombres[random.nextInt(nombres.length)];
                String apellido = apellidos[random.nextInt(apellidos.length)];

                String[] valores = {numDoc, nombre, apellido};
                for (int j = 0; j < campos.length; j++) {
                    Dato dato = new Dato();
                    dato.setCampo(campos[j]);
                    dato.setIndice(i);
                    dato.setPosicion(0);
                    dato.setInformacion(valores[j]);
                    datoRepository.save(dato);
                }
            } catch (Exception e) {
                logger.error("Error al insertar fila {}: {}", i, e.getMessage());
            }
        }

        logger.info("Seed completado: {} tipos de campo + 2 orígenes + 1 lugar + 1 evento + 1 planilla + 3 campos + 30 filas.",
                tiposCampo.size());
    }
}
