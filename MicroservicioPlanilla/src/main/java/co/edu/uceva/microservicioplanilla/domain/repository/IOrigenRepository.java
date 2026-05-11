package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IOrigenRepository extends JpaRepository<Origen, Long> {
    Optional<Origen> findByOrigenIgnoreCase(String origen);
    boolean existsByOrigenIgnoreCase(String origen);
}
