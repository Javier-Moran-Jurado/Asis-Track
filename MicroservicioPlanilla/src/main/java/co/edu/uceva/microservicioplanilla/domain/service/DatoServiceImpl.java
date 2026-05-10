package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DatoServiceImpl implements IDatoService {

    private final IDatoRepository repository;

    @Override public List<Dato> findAll() { return repository.findAll(); }

    @Override
    public Dato findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Dato no encontrado con id: " + id));
    }

    @Override public Dato save(Dato dato) { return repository.save(dato); }

    @Override
    public Dato update(Dato dato) {
        if (!repository.existsById(dato.getId())) {
            throw new RuntimeException("Dato no encontrado con id: " + dato.getId());
        }
        return repository.save(dato);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Dato no encontrado con id: " + id);
        }
        repository.deleteById(id);
    }

    @Override
    public List<Dato> findByPlanillaId(Long planillaId) {
        return repository.findByPlanillaId(planillaId);
    }

    @Override
    public List<Dato> findByPlanillaIdAndIndice(Long planillaId, Integer indice) {
        return repository.findByPlanillaIdAndIndice(planillaId, indice);
    }

    @Override
    public List<Dato> findByCampoId(Long campoId) {
        return repository.findByCampoId(campoId);
    }
}
