package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.repository.IEventoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EventoServiceImpl implements IEventoService {

    private final IEventoRepository repository;
    private final IPlanillaRepository planillaRepository;

    @Override public List<Evento> findAll() { return repository.findAll(); }

    @Override
    public Evento findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Evento no encontrado con id: " + id));
    }

    @Override public Evento save(Evento evento) { return repository.save(evento); }

    @Override
    public Evento update(Evento evento) {
        if (!repository.existsById(evento.getId())) {
            throw new RuntimeException("Evento no encontrado con id: " + evento.getId());
        }
        return repository.save(evento);
    }

    @Override
    public void deleteById(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Evento no encontrado con id: " + id);
        }
        long planillasCount = planillaRepository.countByEventoId(id);
        if (planillasCount > 0) {
            throw new RuntimeException(
                "No se puede eliminar el evento porque tiene " + planillasCount +
                " planilla" + (planillasCount == 1 ? "" : "s") + " asociada" + (planillasCount == 1 ? "" : "s") + ". Elimina primero las planillas."
            );
        }
        repository.deleteById(id);
    }

    @Override
    public List<Evento> findByCodigoUsuario(Long codigoUsuario) {
        return repository.findByCodigoUsuario(codigoUsuario);
    }
}
