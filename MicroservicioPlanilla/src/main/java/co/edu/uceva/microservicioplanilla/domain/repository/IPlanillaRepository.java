package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IPlanillaRepository extends JpaRepository<Planilla, Long> {
}