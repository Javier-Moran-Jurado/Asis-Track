package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IPlanillaRepository extends JpaRepository<Planilla, Long> {
    List<Planilla> findByEventoId(Long eventoId);
    long countByEventoId(Long eventoId);
}