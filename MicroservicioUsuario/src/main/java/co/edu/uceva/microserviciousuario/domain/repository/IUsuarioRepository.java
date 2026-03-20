package co.edu.uceva.microserviciousuario.domain.repository;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.CrudRepository;

public interface IUsuarioRepository extends JpaRepository<Usuario, Long> {
}