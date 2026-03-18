package co.edu.uceva.microserviciousuario.domain.service;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public class UsuarioServiceImpl implements IUsuarioService {

    private IUsuarioRepository repository;

    @Override
    public List<Usuario> findAll() {
        return repository.findAll();
    }

    @Override
    public Optional<Usuario> findById(long id) {
        return repository.findById(id);
    }

    @Override
    public Usuario update(Usuario usuario) {
        return repository.save(usuario);
    }

    @Override
    public Usuario save(Usuario usuario) {
        return repository.save(usuario);
    }

    @Override
    public void delete(Usuario usuario) {
        repository.delete(usuario);
    }

    @Override
    public Page<Usuario> findAll(Pageable pageable) {
        return repository.findAll(pageable);
    }
}