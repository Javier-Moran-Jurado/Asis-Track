package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.PlanillaRequest;
import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.repository.IOrigenRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IEventoRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PlanillaServiceImpl implements IPlanillaService {

    private final IPlanillaRepository repository;
    private final IOrigenRepository origenRepository;
    private final IEventoRepository eventoRepository;

    public PlanillaServiceImpl(IPlanillaRepository repository, IOrigenRepository origenRepository, IEventoRepository eventoRepository) {
        this.repository = repository;
        this.origenRepository = origenRepository;
        this.eventoRepository = eventoRepository;
    }

    @Override
    public List<Planilla> findAll() {
        return repository.findAll();
    }

    @Override
    public Planilla findById(long id) {
        return repository.findById(id).orElse(null);
    }

    @Override
    public Planilla save(PlanillaRequest request) {
        Planilla planilla = new Planilla();
        mapRequestToEntity(planilla, request);
        return repository.save(planilla);
    }

    @Override
    public Planilla update(Long id, PlanillaRequest request) {
        Planilla planilla = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Planilla no encontrada con id: " + id));
        mapRequestToEntity(planilla, request);
        return repository.save(planilla);
    }

    @Override
    public void deleteById(long id) {
        repository.deleteById(id);
    }

    @Override
    public Page<Planilla> findAll(Pageable pageable) {
        return repository.findAll(pageable);
    }

    private void mapRequestToEntity(Planilla planilla, PlanillaRequest request) {
        if (request.getOrigenId() != null) {
            Origen origen = origenRepository.findById(request.getOrigenId())
                    .orElseThrow(() -> new RuntimeException("Origen no encontrado: " + request.getOrigenId()));
            planilla.setOrigen(origen);
        }
        if (request.getEventoId() != null) {
            Evento evento = eventoRepository.findById(request.getEventoId())
                    .orElseThrow(() -> new RuntimeException("Evento no encontrado: " + request.getEventoId()));
            planilla.setEvento(evento);
        }
        planilla.setUrlReferencia(request.getUrlReferencia());
        planilla.setQrUrl(request.getQrUrl());
    }
}
