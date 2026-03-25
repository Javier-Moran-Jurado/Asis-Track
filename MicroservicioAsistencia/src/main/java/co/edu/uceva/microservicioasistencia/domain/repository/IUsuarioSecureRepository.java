package co.edu.uceva.microservicioasistencia.domain.repository;

import co.edu.uceva.microservicioasistencia.domain.model.UsuarioSecure;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUsuarioSecureRepository extends JpaRepository<UsuarioSecure, Long> {
}
