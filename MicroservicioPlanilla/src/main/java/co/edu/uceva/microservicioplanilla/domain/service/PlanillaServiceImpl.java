package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PlanillaServiceImpl implements IPlanillaService {

    private IPlanillaRepository repository;

    public PlanillaServiceImpl(IPlanillaRepository repository) {
        this.repository = repository;
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
    public Planilla update(Planilla planilla) {
        return repository.save(planilla);
    }

    @Override
    public Planilla save(Planilla planilla) {
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
}