package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CampoServiceImpl implements ICampoService {

    private final ICampoRepository repository;

    @Override public List<Campo> findAll() { return repository.findAll(); }

    @Override
    public Campo findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Campo no encontrado con id: " + id));
    }

    @Override public Campo save(Campo campo) { return repository.save(campo); }

    @Override
    public Campo update(Campo campo) {
        if (!repository.existsById(campo.getId())) {
            throw new RuntimeException("Campo no encontrado con id: " + campo.getId());
        }
        return repository.save(campo);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Campo no encontrado con id: " + id);
        }
        repository.deleteById(id);
    }

    @Override
    public List<Campo> findByPlanillaId(Long planillaId) {
        return repository.findByPlanillaId(planillaId);
    }
}
