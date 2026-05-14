package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.exception.ResourceNotFoundException;
import co.edu.uceva.microservicioplanilla.domain.model.EstadoJustificacion;
import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.model.Justificacion;
import co.edu.uceva.microservicioplanilla.domain.repository.IEventoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IJustificacionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class JustificacionServiceImpl implements IJustificacionService {

    private final IJustificacionRepository justificacionRepository;
    private final IEventoRepository eventoRepository;

    @Override
    @Transactional
    public Justificacion solicitarJustificacion(Long eventoId, Long codigoEstudiante, String motivo, String documentoUrl) {
        Evento evento = eventoRepository.findById(eventoId)
                .orElseThrow(() -> new ResourceNotFoundException("Evento no encontrado con id: " + eventoId));

        Justificacion justificacion = new Justificacion();
        justificacion.setEvento(evento);
        justificacion.setCodigoEstudiante(codigoEstudiante);
        justificacion.setMotivo(motivo);
        justificacion.setDocumentoUrl(documentoUrl);
        justificacion.setEstado(EstadoJustificacion.PENDIENTE);
        justificacion.setFechaSolicitud(LocalDateTime.now());
        return justificacionRepository.save(justificacion);
    }

    @Override
    @Transactional
    public Justificacion aprobarJustificacion(Long id, Long codigoDecano, String observaciones) {
        Justificacion justificacion = findById(id);
        justificacion.setEstado(EstadoJustificacion.APROBADO);
        justificacion.setCodigoDecano(codigoDecano);
        justificacion.setFechaRevision(LocalDateTime.now());
        justificacion.setObservaciones(observaciones);
        return justificacionRepository.save(justificacion);
    }

    @Override
    @Transactional
    public Justificacion rechazarJustificacion(Long id, Long codigoDecano, String observaciones) {
        Justificacion justificacion = findById(id);
        justificacion.setEstado(EstadoJustificacion.RECHAZADO);
        justificacion.setCodigoDecano(codigoDecano);
        justificacion.setFechaRevision(LocalDateTime.now());
        justificacion.setObservaciones(observaciones);
        return justificacionRepository.save(justificacion);
    }

    @Override
    public Justificacion findById(Long id) {
        return justificacionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Justificación no encontrada con id: " + id));
    }

    @Override
    public List<Justificacion> findByCodigoEstudiante(Long codigoEstudiante) {
        return justificacionRepository.findByCodigoEstudiante(codigoEstudiante);
    }

    @Override
    public List<Justificacion> findByEventoId(Long eventoId) {
        return justificacionRepository.findByEventoId(eventoId);
    }

    @Override
    public List<Justificacion> findByEstado(EstadoJustificacion estado) {
        return justificacionRepository.findByEstado(estado);
    }

    @Override
    public List<Justificacion> findAll() {
        return justificacionRepository.findAll();
    }

    @Override
    @Transactional
    public Justificacion update(Justificacion justificacion) {
        Justificacion existing = justificacionRepository.findById(justificacion.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Justificación no encontrada con id: " + justificacion.getId()));

        if (justificacion.getEvento() != null) existing.setEvento(justificacion.getEvento());
        if (justificacion.getCodigoEstudiante() != null) existing.setCodigoEstudiante(justificacion.getCodigoEstudiante());
        if (justificacion.getCodigoDecano() != null) existing.setCodigoDecano(justificacion.getCodigoDecano());
        if (justificacion.getMotivo() != null) existing.setMotivo(justificacion.getMotivo());
        if (justificacion.getDocumentoUrl() != null) existing.setDocumentoUrl(justificacion.getDocumentoUrl());
        if (justificacion.getEstado() != null) existing.setEstado(justificacion.getEstado());
        if (justificacion.getObservaciones() != null) existing.setObservaciones(justificacion.getObservaciones());

        return justificacionRepository.save(existing);
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
