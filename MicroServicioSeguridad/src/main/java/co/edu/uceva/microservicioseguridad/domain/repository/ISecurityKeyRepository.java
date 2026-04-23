package co.edu.uceva.microservicioseguridad.domain.repository;

import co.edu.uceva.microservicioseguridad.domain.model.SecurityKey;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ISecurityKeyRepository extends JpaRepository<SecurityKey, Long> {
    Optional<SecurityKey> findByActiveTrue();
}
