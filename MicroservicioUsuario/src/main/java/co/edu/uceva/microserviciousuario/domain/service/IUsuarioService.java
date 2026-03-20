package co.edu.uceva.microserviciousuario.domain.service;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;

public interface IUsuarioService {
    List<Usuario> findAll();
    Optional<Usuario> findById(long id);
    Usuario update(Usuario usuario);
    Usuario save(Usuario usuario);
    void delete(Usuario usuario);
    Page<Usuario> findAll(Pageable pageable);
}