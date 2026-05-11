package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import co.edu.uceva.microservicioplanilla.domain.repository.ICampoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IDatoRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IFilaRepository;
import co.edu.uceva.microservicioplanilla.domain.repository.IPlanillaRepository;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.DatoSinFilaRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.FilaRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FilaServiceImpl implements IFilaService {

    private final IFilaRepository filaRepository;
    private final IPlanillaRepository planillaRepository;
    private final ICampoRepository campoRepository;
    private final IDatoRepository datoRepository;

    @Override
    public List<Fila> findAll() {
        return filaRepository.findAll();
    }

    @Override
    public Fila findById(Long id) {
        return filaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Fila no encontrada con id: " + id));
    }

    @Override
    public List<Fila> findByPlanillaId(Long planillaId) {
        return filaRepository.findByPlanillaId(planillaId);
    }

    @Override
    public List<Fila> findByCodigoUsuario(Long codigoUsuario) {
        return filaRepository.findByCodigoUsuario(codigoUsuario);
    }

    @Override
    public Fila findByPlanillaIdAndIndice(Long planillaId, Integer indice) {
        return filaRepository.findByPlanillaIdAndIndice(planillaId, indice)
                .orElseThrow(() -> new RuntimeException("Fila no encontrada para planilla " + planillaId + " e indice " + indice));
    }

    @Override
    @Transactional
    public Fila create(FilaRequest request) {
        Long codigoUsuario = request.getCodigoUsuario();
        if (codigoUsuario == null) {
            codigoUsuario = getCurrentUserCodigo();
        }

        Planilla planilla = planillaRepository.findById(request.getPlanillaId())
                .orElseThrow(() -> new IllegalArgumentException("Planilla no encontrada: " + request.getPlanillaId()));

        Fila fila = new Fila();
        fila.setPlanilla(planilla);
        fila.setIndice(request.getIndice());
        fila.setCodigoUsuario(codigoUsuario);

        List<Dato> datos = mapDatos(request.getDatos(), fila);
        fila.setDatos(datos);

        return filaRepository.save(fila);
    }

    @Override
    @Transactional
    public List<Fila> createBatch(List<FilaRequest> requests) {
        List<Fila> resultados = new ArrayList<>();
        for (FilaRequest req : requests) {
            resultados.add(create(req));
        }
        return resultados;
    }

    @Override
    @Transactional
    public Fila updateFull(Long id, FilaRequest request) {
        Fila fila = findById(id);
        assertOwnershipOrAdmin(fila);

        if (request.getIndice() != null) {
            fila.setIndice(request.getIndice());
        }

        // Reemplazo total de datos
        datoRepository.deleteByFilaId(fila.getId());
        if (fila.getDatos() != null) {
            fila.getDatos().clear();
        }
        List<Dato> nuevosDatos = mapDatos(request.getDatos(), fila);
        fila.getDatos().addAll(nuevosDatos);

        return filaRepository.save(fila);
    }

    @Override
    @Transactional
    public Fila patch(Long id, FilaRequest request) {
        Fila fila = findById(id);
        assertOwnershipOrAdmin(fila);

        if (request.getIndice() != null) {
            fila.setIndice(request.getIndice());
        }

        if (request.getDatos() != null) {
            for (DatoSinFilaRequest datoReq : request.getDatos()) {
                Campo campo = campoRepository.findById(datoReq.getCampoId())
                        .orElseThrow(() -> new IllegalArgumentException("Campo no encontrado: " + datoReq.getCampoId()));
                validateCampoBelongsToPlanilla(campo, fila.getPlanilla());

                Dato existente = datoRepository
                        .findByCampoIdAndFilaIdAndPosicion(campo.getId(), fila.getId(), datoReq.getPosicion())
                        .orElse(null);

                if (existente != null) {
                    existente.setInformacion(datoReq.getInformacion());
                } else {
                    Dato nuevo = new Dato();
                    nuevo.setCampo(campo);
                    nuevo.setFila(fila);
                    nuevo.setPosicion(datoReq.getPosicion());
                    nuevo.setInformacion(datoReq.getInformacion());
                    fila.getDatos().add(nuevo);
                }
            }
        }

        return filaRepository.save(fila);
    }

    @Override
    @Transactional
    public void deleteById(Long id) {
        Fila fila = findById(id);
        assertOwnershipOrAdmin(fila);
        filaRepository.deleteById(id);
    }

    private List<Dato> mapDatos(List<DatoSinFilaRequest> requests, Fila fila) {
        if (requests == null) return new ArrayList<>();
        List<Dato> datos = new ArrayList<>();
        for (DatoSinFilaRequest req : requests) {
            Campo campo = campoRepository.findById(req.getCampoId())
                    .orElseThrow(() -> new IllegalArgumentException("Campo no encontrado: " + req.getCampoId()));
            validateCampoBelongsToPlanilla(campo, fila.getPlanilla());

            Dato dato = new Dato();
            dato.setCampo(campo);
            dato.setFila(fila);
            dato.setPosicion(req.getPosicion());
            dato.setInformacion(req.getInformacion());
            datos.add(dato);
        }
        return datos;
    }

    private void validateCampoBelongsToPlanilla(Campo campo, Planilla planilla) {
        if (!campo.getPlanilla().getId().equals(planilla.getId())) {
            throw new IllegalArgumentException(
                    "Campo " + campo.getId() + " no pertenece a la planilla " + planilla.getId());
        }
    }

    private void assertOwnershipOrAdmin(Fila fila) {
        Long currentUser = getCurrentUserCodigo();
        boolean isOwner = fila.getCodigoUsuario() != null && fila.getCodigoUsuario().equals(currentUser);
        boolean isAdmin = isAdmin();
        if (!isOwner && !isAdmin) {
            throw new AccessDeniedException("No autorizado para modificar esta fila");
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
