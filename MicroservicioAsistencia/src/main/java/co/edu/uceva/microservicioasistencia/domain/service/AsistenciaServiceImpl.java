package co.edu.uceva.microservicioasistencia.domain.service;

import co.edu.uceva.microservicioasistencia.domain.model.Asistencia;
import co.edu.uceva.microservicioasistencia.domain.repository.IAsistenciaRepository;
import co.edu.uceva.microservicioasistencia.domain.service.IAsistenciaService;
import co.edu.uceva.microservicioasistencia.domain.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AsistenciaServiceImpl implements IAsistenciaService {

    private final IAsistenciaRepository asistenciaRepository;

    @Override
    @Transactional
    public Asistencia registrarEntrada(String codigoEstudiante, Long planillaId,
                                       String geolocalizacion, String datosAdicionales) {
        Asistencia asistencia = new Asistencia();
        asistencia.setCodigoEstudiante(codigoEstudiante);
        asistencia.setPlanillaId(planillaId);
        asistencia.setFechaHoraRegistro(LocalDateTime.now());
        asistencia.setEstado("PRESENTE");
        asistencia.setGeolocalizacion(geolocalizacion);
        asistencia.setDatosAdicionales(datosAdicionales);
        return asistenciaRepository.save(asistencia);
    }

    @Override
    @Transactional
    public Asistencia registrarSalida(String codigoEstudiante, Long planillaId,
                                      String geolocalizacion, String datosAdicionales) {
        Asistencia asistencia = new Asistencia();
        asistencia.setCodigoEstudiante(codigoEstudiante);
        asistencia.setPlanillaId(planillaId);
        asistencia.setFechaHoraRegistro(LocalDateTime.now());
        asistencia.setEstado("SALIDA");
        asistencia.setGeolocalizacion(geolocalizacion);
        asistencia.setDatosAdicionales(datosAdicionales);
        return asistenciaRepository.save(asistencia);
    }

    @Override
    @Transactional
    public Asistencia justificarAusencia(String codigoEstudiante, Long planillaId, String datosAdicionales) {
        Asistencia asistencia = new Asistencia();
        asistencia.setCodigoEstudiante(codigoEstudiante);
        asistencia.setPlanillaId(planillaId);
        asistencia.setFechaHoraRegistro(LocalDateTime.now());
        asistencia.setEstado("JUSTIFICADO");
        asistencia.setDatosAdicionales(datosAdicionales);
        return asistenciaRepository.save(asistencia);
    }

    @Override
    public Asistencia findById(Long id) {
        return asistenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Asistencia no encontrada con id: " + id));
    }

    @Override
    public List<Asistencia> findByCodigoEstudiante(String codigoEstudiante) {
        return asistenciaRepository.findByCodigoEstudiante(codigoEstudiante);
    }

    @Override
    public List<Asistencia> findByPlanillaId(Long planillaId) {
        return asistenciaRepository.findByPlanillaId(planillaId);
    }

    @Override
    public List<Asistencia> findPresentesByPlanilla(Long planillaId) {
        return asistenciaRepository.findPresentesByPlanilla(planillaId);
    }

    @Override
    public List<Asistencia> findByFechaHoraRegistroBetween(LocalDateTime inicio, LocalDateTime fin) {
        return asistenciaRepository.findByFechaHoraRegistroBetween(inicio, fin);
    }

    @Override
    @Transactional
    public Asistencia update(Asistencia asistencia) {
        Asistencia existente = asistenciaRepository.findById(asistencia.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Asistencia no encontrada con id: " + asistencia.getId()));

        if (asistencia.getEstado() != null) {
            existente.setEstado(asistencia.getEstado());
        }
        if (asistencia.getGeolocalizacion() != null) {
            existente.setGeolocalizacion(asistencia.getGeolocalizacion());
        }
        if (asistencia.getDatosAdicionales() != null) {
            existente.setDatosAdicionales(asistencia.getDatosAdicionales());
        }

        return asistenciaRepository.save(existente);
    }

    @Override
    @Transactional
    public void deleteById(Long id) {
        if (!asistenciaRepository.existsById(id)) {
            throw new ResourceNotFoundException("Asistencia no encontrada con id: " + id);
        }
        asistenciaRepository.deleteById(id);
    }

    @Override
    @Transactional
    public Asistencia actualizarEstado(Long id, String nuevoEstado) {
        Asistencia existente = findById(id);
        existente.setEstado(nuevoEstado);
        return asistenciaRepository.save(existente);
    }
}