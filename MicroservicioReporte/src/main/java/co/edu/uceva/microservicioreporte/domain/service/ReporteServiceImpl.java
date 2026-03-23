package co.edu.uceva.microservicioreporte.domain.service;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;
import co.edu.uceva.microservicioreporte.domain.repository.IReporteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReporteServiceImpl implements IReporteService {

    private final IReporteRepository repository;

    public ReporteServiceImpl(IReporteRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<Reporte> findAll() {
        return repository.findAll();
    }

    @Override
    public Reporte findById(Long id) {
        return repository.findById(id).orElse(null);
    }

    @Override
    public Reporte save(Reporte reporte) {
        return repository.save(reporte);
    }

    @Override
    public Reporte update(Reporte reporte) {
        return repository.save(reporte);
    }

    @Override
    public void deleteById(Long id) {
        repository.deleteById(id);
    }
}