package co.edu.uceva.microservicioreporte.domain.repository;

import co.edu.uceva.microservicioreporte.domain.model.UsuarioSecure;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUsuarioSecureRepository extends JpaRepository<UsuarioSecure, Long> {
}
