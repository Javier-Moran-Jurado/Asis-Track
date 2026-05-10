package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DatoServiceImpl implements IDatoService {

    private final IDatoRepository repository;
    private final ICampoService campoService;
    private final ICampoRepository campoRepository;

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

    @Override
    @Transactional
    public List<Dato> saveAll(List<DatoRequest> requests) {
        // 1. Validar que todos los campoId existen
        List<Long> idsInvalidos = requests.stream()
            .map(DatoRequest::getCampoId)
            .filter(id -> !campoService.existsById(id))
            .distinct().toList();

        if (!idsInvalidos.isEmpty()) {
            throw new IllegalArgumentException("IDs de campo inválidos: " + idsInvalidos);
        }

        // 2. Mapear DTO a entidad
        List<Dato> datos = requests.stream().map(req -> {
            Dato d = new Dato();
            d.setCampo(campoRepository.getReferenceById(req.getCampoId()));
            d.setIndice(req.getIndice());
            d.setPosicion(req.getPosicion());
            d.setInformacion(req.getInformacion());
            return d;
        }).toList();

        // 3. Guardar en lote
        return repository.saveAll(datos);
    }
}
