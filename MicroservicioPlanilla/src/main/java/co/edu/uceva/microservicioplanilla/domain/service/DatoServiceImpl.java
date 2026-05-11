package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IFilaRepository;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DatoServiceImpl implements IDatoService {

    private final IDatoRepository repository;
    private final ICampoService campoService;
    private final ICampoRepository campoRepository;
    private final IFilaRepository filaRepository;

    @Override
    public List<Dato> findAll() {
        return repository.findAll();
    }

    @Override
    public Dato findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Dato no encontrado con id: " + id));
    }

    @Override
    @Transactional
    public Dato save(DatoRequest request) {
        Dato d = new Dato();
        d.setCampo(campoRepository.getReferenceById(request.getCampoId()));
        d.setFila(filaRepository.getReferenceById(request.getFilaId()));
        d.setPosicion(request.getPosicion());
        d.setInformacion(request.getInformacion());
        return repository.save(d);
    }

    @Override
    @Transactional
    public Dato update(Long id, DatoRequest request) {
        Dato existente = findById(id);
        assertOwnershipOrAdmin(existente.getFila());
        existente.setCampo(campoRepository.getReferenceById(request.getCampoId()));
        existente.setFila(filaRepository.getReferenceById(request.getFilaId()));
        existente.setPosicion(request.getPosicion());
        existente.setInformacion(request.getInformacion());
        return repository.save(existente);
    }

    @Override
    @Transactional
    public void deleteById(Long id) {
        Dato dato = findById(id);
        assertOwnershipOrAdmin(dato.getFila());
        repository.deleteById(id);
    }

    @Override
    public List<Dato> findByPlanillaId(Long planillaId) {
        return repository.findByPlanillaId(planillaId);
    }

    @Override
    public List<Dato> findByCampoId(Long campoId) {
        return repository.findByCampoId(campoId);
    }

    @Override
    @Transactional
    public List<Dato> saveAll(List<DatoRequest> requests) {
        List<Long> idsInvalidos = requests.stream()
                .map(DatoRequest::getCampoId)
                .filter(id -> !campoService.existsById(id))
                .distinct().toList();

        if (!idsInvalidos.isEmpty()) {
            throw new IllegalArgumentException("IDs de campo inválidos: " + idsInvalidos);
        }

        List<Long> filaIdsInvalidos = requests.stream()
                .map(DatoRequest::getFilaId)
                .filter(id -> !filaRepository.existsById(id))
                .distinct().toList();

        if (!filaIdsInvalidos.isEmpty()) {
            throw new IllegalArgumentException("IDs de fila inválidos: " + filaIdsInvalidos);
        }

        List<Dato> datos = requests.stream().map(req -> {
            Dato d = new Dato();
            d.setCampo(campoRepository.getReferenceById(req.getCampoId()));
            d.setFila(filaRepository.getReferenceById(req.getFilaId()));
            d.setPosicion(req.getPosicion());
            d.setInformacion(req.getInformacion());
            return d;
        }).toList();

        return repository.saveAll(datos);
    }

    private void assertOwnershipOrAdmin(Fila fila) {
        Long currentUser = getCurrentUserCodigo();
        boolean isOwner = fila.getCodigoUsuario() != null && fila.getCodigoUsuario().equals(currentUser);
        boolean isAdmin = isAdmin();
        if (!isOwner && !isAdmin) {
            throw new AccessDeniedException("No autorizado para modificar este dato");
        }
    }

    private Long getCurrentUserCodigo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetails userDetails) {
            return Long.parseLong(userDetails.getUsername());
        }
        return null;
    }

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_Administrador") || a.getAuthority().equals("ROLE_Administrativo"));
    }
}
