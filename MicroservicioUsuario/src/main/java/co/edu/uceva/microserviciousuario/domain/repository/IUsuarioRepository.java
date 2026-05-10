package co.edu.uceva.microserviciousuario.domain.repository;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.CrudRepository;

import java.util.Optional;

public interface IUsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByCedula(Long cedula);
    Optional<Usuario> findByCodigo(Long codigo);
}