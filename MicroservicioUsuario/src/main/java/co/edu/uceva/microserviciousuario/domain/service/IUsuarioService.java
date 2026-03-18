package co.edu.uceva.microserviciousuario.domain.service;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.CrudRepository;


import java.util.List;

public interface IUsuarioService {
    public List<Usuario> findAll();
    public Usuario findById(long id);
    public Usuario update(Usuario usuario);
    public Usuario save(Usuario usuario);
    public void delete(Usuario usuario);
    public Page<Usuario> findAll(Pageable pageable);
}