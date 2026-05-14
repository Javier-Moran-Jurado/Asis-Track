package co.edu.uceva.microserviciousuario.domain.service;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;

@Service
public class UsuarioServiceImpl implements IUsuarioService {

    IUsuarioRepository repository;

    public UsuarioServiceImpl(IUsuarioRepository repository) {
        this.repository = repository;
    }

    @Override
    @Transactional
    public List<Usuario> findAll() {
        return repository.findAll();
    }

    @Override
    @Transactional
    public Optional<Usuario> findById(long id) {
        return repository.findById(id);
    }

    @Override
    @Transactional
    public Usuario update(Usuario usuario) {
        Usuario existente = repository.findById(usuario.getCodigo())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con codigo: " + usuario.getCodigo()));

        if (usuario.getNombreCompleto() != null && !usuario.getNombreCompleto().isEmpty()) {
            existente.setNombreCompleto(usuario.getNombreCompleto());
        }
        if (usuario.getCorreo() != null && !usuario.getCorreo().isEmpty()) {
            existente.setCorreo(usuario.getCorreo());
        }
        if (usuario.getContrasena() != null && !usuario.getContrasena().isEmpty()) {
            existente.setContrasena(usuario.getContrasena());
        }
        if (usuario.getCedula() != null) {
            existente.setCedula(usuario.getCedula());
        }
        if (usuario.getTelefono() != null) {
            existente.setTelefono(usuario.getTelefono());
        }
        if (usuario.getRol() != null) {
            existente.setRol(usuario.getRol());
        }

        return repository.save(existente);
    }

    @Override
    @Transactional
    public Usuario save(Usuario usuario) {
        return repository.save(usuario);
    }

    @Override
    @Transactional
    public void delete(Usuario usuario) {
        repository.delete(usuario);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Usuario> findAll(Pageable pageable) {
        return repository.findAll(pageable);
    }
}