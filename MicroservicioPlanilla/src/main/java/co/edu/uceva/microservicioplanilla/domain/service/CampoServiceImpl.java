package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.model.OpcionesCampo;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.ITipoCampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IOpcionesCampoRepository;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.CampoRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CampoServiceImpl implements ICampoService {

    private final ICampoRepository repository;
    private final IPlanillaRepository planillaRepository;
    private final ITipoCampoRepository tipoCampoRepository;
    private final IOpcionesCampoRepository opcionesCampoRepository;

    @Override public List<Campo> findAll() { return repository.findAll(); }

    @Override
    public Campo findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Campo no encontrado con id: " + id));
    }

    @Override public Campo save(Campo campo) { return repository.save(campo); }

    @Override
    public Campo save(CampoRequest request) {
        return saveAll(List.of(request)).get(0);
    }

    @Override
    public Campo update(Campo campo) {
        if (!repository.existsById(campo.getId())) {
            throw new RuntimeException("Campo no encontrado con id: " + campo.getId());
        }
        return repository.save(campo);
    }

    @Override
    public Campo update(Long id, CampoRequest request) {
        Campo existente = findById(id);
        existente.setPlanilla(planillaRepository.findById(request.getPlanillaId())
                .orElseThrow(() -> new IllegalArgumentException("Planilla no encontrada: " + request.getPlanillaId())));
        existente.setTipoCampo(tipoCampoRepository.findById(request.getTipoCampoId())
                .orElseThrow(() -> new IllegalArgumentException("Tipo de campo no encontrado: " + request.getTipoCampoId())));
        existente.setNombreCampo(request.getNombreCampo());
        existente.setObligatorio(Boolean.TRUE.equals(request.getObligatorio()));
        return repository.save(existente);
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

    @Override
    public boolean existsById(Long id) {
        return repository.existsById(id);
    }

    @Override
    @Transactional
    public List<Campo> saveAll(List<CampoRequest> requests) {
        // 1. Validar existencia de planillas y tipos de campo referenciados
        List<Long> planillaIdsInvalidos = requests.stream()
            .map(CampoRequest::getPlanillaId)
            .filter(id -> !planillaRepository.existsById(id))
            .distinct().toList();

        if (!planillaIdsInvalidos.isEmpty()) {
            throw new IllegalArgumentException("IDs de planilla inválidos: " + planillaIdsInvalidos);
        }

        List<Long> tipoIdsInvalidos = requests.stream()
            .map(CampoRequest::getTipoCampoId)
            .filter(id -> !tipoCampoRepository.existsById(id))
            .distinct().toList();

        if (!tipoIdsInvalidos.isEmpty()) {
            throw new IllegalArgumentException("IDs de tipo de campo inválidos: " + tipoIdsInvalidos);
        }

        // 2. Mapear y guardar Campos
        List<Campo> campos = requests.stream().map(req -> {
            Campo c = new Campo();
            c.setPlanilla(planillaRepository.findById(req.getPlanillaId())
                    .orElseThrow(() -> new IllegalArgumentException("Planilla no encontrada: " + req.getPlanillaId())));
            c.setTipoCampo(tipoCampoRepository.findById(req.getTipoCampoId())
                    .orElseThrow(() -> new IllegalArgumentException("Tipo de campo no encontrado: " + req.getTipoCampoId())));
            c.setNombreCampo(req.getNombreCampo());
            c.setObligatorio(Boolean.TRUE.equals(req.getObligatorio()));
            return c;
        }).toList();

        List<Campo> savedCampos = repository.saveAll(campos);

        // 3. Guardar opciones para los campos que las tienen
        List<OpcionesCampo> todasOpciones = new ArrayList<>();
        for (int i = 0; i < requests.size(); i++) {
            List<String> opciones = requests.get(i).getOpciones();
            if (opciones != null && !opciones.isEmpty()) {
                Campo campoGuardado = savedCampos.get(i);
                for (int j = 0; j < opciones.size(); j++) {
                    OpcionesCampo op = new OpcionesCampo();
                    op.setCampo(campoGuardado);
                    op.setValor(opciones.get(j));
                    op.setOrden(j);
                    todasOpciones.add(op);
                }
            }
        }

        if (!todasOpciones.isEmpty()) {
            opcionesCampoRepository.saveAll(todasOpciones);
        }

        return savedCampos;
    }
}
