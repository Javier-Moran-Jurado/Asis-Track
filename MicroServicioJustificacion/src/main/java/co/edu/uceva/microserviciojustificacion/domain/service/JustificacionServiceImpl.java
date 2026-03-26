package co.edu.uceva.microserviciojustificacion.domain.service;

import co.edu.uceva.microserviciojustificacion.domain.model.Justificacion;
import co.edu.uceva.microserviciojustificacion.domain.repository.IJustificacionRepository;
import co.edu.uceva.microserviciojustificacion.domain.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class JustificacionServiceImpl implements IJustificacionService {

    private final IJustificacionRepository justificacionRepository;

    @Override
    @Transactional
    public Justificacion solicitarJustificacion(Long registroId, String usuarioCodigo,
                                                String motivo, String documentoUrl) {
        Justificacion justificacion = new Justificacion();
        justificacion.setRegistroId(registroId);
        justificacion.setUsuarioCodigo(usuarioCodigo);
        justificacion.setMotivo(motivo);
        justificacion.setDocumentoUrl(documentoUrl);
        justificacion.setEstado("PENDIENTE");
        justificacion.setFechaSolicitud(LocalDateTime.now());
        return justificacionRepository.save(justificacion);
    }

    @Override
    @Transactional
    public Justificacion aprobarJustificacion(Long id, String revisadoPor, String observaciones) {
        Justificacion justificacion = findById(id);
        justificacion.setEstado("APROBADO");
        justificacion.setFechaRevision(LocalDateTime.now());
        justificacion.setRevisadoPor(revisadoPor);
        justificacion.setObservaciones(observaciones);
        return justificacionRepository.save(justificacion);
    }

    @Override
    @Transactional
    public Justificacion rechazarJustificacion(Long id, String revisadoPor, String observaciones) {
        Justificacion justificacion = findById(id);
        justificacion.setEstado("RECHAZADO");
        justificacion.setFechaRevision(LocalDateTime.now());
        justificacion.setRevisadoPor(revisadoPor);
        justificacion.setObservaciones(observaciones);
        return justificacionRepository.save(justificacion);
    }

    @Override
    public Justificacion findById(Long id) {
        return justificacionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Justificación no encontrada con id: " + id));
    }

    @Override
    public List<Justificacion> findByUsuarioCodigo(String usuarioCodigo) {
        return justificacionRepository.findByUsuarioCodigo(usuarioCodigo);
    }

    @Override
    public List<Justificacion> findByRegistroId(Long registroId) {
        return justificacionRepository.findByRegistroId(registroId);
    }

    @Override
    public List<Justificacion> findByEstado(String estado) {
        return justificacionRepository.findByEstado(estado);
    }

    @Override
    public List<Justificacion> findAll() {
        return justificacionRepository.findAll();
    }

    @Override
    @Transactional
    public Justificacion update(Justificacion justificacion) {
        if (!justificacionRepository.existsById(justificacion.getId())) {
            throw new ResourceNotFoundException("Justificación no encontrada con id: " + justificacion.getId());
        }
        return justificacionRepository.save(justificacion);
    }

    @Override
    @Transactional
    public void deleteById(Long id) {
        if (!justificacionRepository.existsById(id)) {
            throw new ResourceNotFoundException("Justificación no encontrada con id: " + id);
        }
        justificacionRepository.deleteById(id);
    }
}
