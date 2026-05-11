package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;
import co.edu.uceva.microservicioplanilla.domain.repository.ILugarRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class LugarServiceImpl implements ILugarService {

    private final ILugarRepository repository;

    @Override public List<Lugar> findAll() { return repository.findAll(); }

    @Override
    public Lugar findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Lugar no encontrado con id: " + id));
    }

    @Override public Lugar save(Lugar lugar) { return repository.save(lugar); }

    @Override
    public Lugar update(Lugar lugar) {
        if (!repository.existsById(lugar.getId())) {
            throw new RuntimeException("Lugar no encontrado con id: " + lugar.getId());
        }
        return repository.save(lugar);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Lugar no encontrado con id: " + id);
        }
        repository.deleteById(id);
    }
}
