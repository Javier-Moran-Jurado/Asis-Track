package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ITipoCampoRepository extends JpaRepository<TipoCampo, Long> {
    Optional<TipoCampo> findByTipoIgnoreCase(String tipo);
    boolean existsByTipoIgnoreCase(String tipo);
}
