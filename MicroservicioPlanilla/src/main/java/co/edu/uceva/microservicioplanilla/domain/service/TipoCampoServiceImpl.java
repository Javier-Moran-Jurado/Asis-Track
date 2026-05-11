package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TipoCampoServiceImpl implements ITipoCampoService {

    private final ITipoCampoRepository repository;

    @Override public List<TipoCampo> findAll() { return repository.findAll(); }

    @Override
    public TipoCampo findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("TipoCampo no encontrado con id: " + id));
    }

    @Override public TipoCampo save(TipoCampo tipoCampo) { return repository.save(tipoCampo); }

    @Override
    public TipoCampo update(TipoCampo tipoCampo) {
        if (!repository.existsById(tipoCampo.getId())) {
            throw new RuntimeException("TipoCampo no encontrado con id: " + tipoCampo.getId());
        }
        return repository.save(tipoCampo);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("TipoCampo no encontrado con id: " + id);
        }
        repository.deleteById(id);
    }
}
