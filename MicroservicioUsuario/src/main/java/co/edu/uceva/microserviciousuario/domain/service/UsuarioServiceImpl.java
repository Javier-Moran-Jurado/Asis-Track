package co.edu.uceva.microserviciousuario.domain.service;

import java.util.List;

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
    public Usuario findById(long id) {
        return repository.findById(id).orElse(null);
    }

    @Override
    @Transactional
    public Usuario update(Usuario usuario) {
        return repository.save(usuario);
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