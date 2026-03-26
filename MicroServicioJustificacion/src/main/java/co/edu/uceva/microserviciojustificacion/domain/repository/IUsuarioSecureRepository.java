package co.edu.uceva.microserviciojustificacion.domain.repository;

import co.edu.uceva.microserviciojustificacion.domain.model.UsuarioSecure;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUsuarioSecureRepository extends JpaRepository<UsuarioSecure, Long> {
}
