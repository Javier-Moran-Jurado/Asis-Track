package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import co.edu.uceva.microservicioplanilla.domain.repository.IOrigenRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class OrigenServiceImpl implements IOrigenService {

    private final IOrigenRepository repository;

    @Override public List<Origen> findAll() { return repository.findAll(); }

    @Override
    public Origen findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Origen no encontrado con id: " + id));
    }

    @Override public Origen save(Origen origen) { return repository.save(origen); }

    @Override
    public Origen update(Origen origen) {
        if (!repository.existsById(origen.getId())) {
            throw new RuntimeException("Origen no encontrado con id: " + origen.getId());
        }
        return repository.save(origen);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Origen no encontrado con id: " + id);
        }
        repository.deleteById(id);
    }
}
