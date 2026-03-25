package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.UsuarioSecure;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUsuarioSecureRepository extends JpaRepository<UsuarioSecure, Long> {
}
