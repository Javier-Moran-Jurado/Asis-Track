package co.edu.uceva.microservicioreporte.domain.repository;

import co.edu.uceva.microservicioreporte.domain.model.Reporte;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IReporteRepository extends JpaRepository<Reporte, Long> {
}