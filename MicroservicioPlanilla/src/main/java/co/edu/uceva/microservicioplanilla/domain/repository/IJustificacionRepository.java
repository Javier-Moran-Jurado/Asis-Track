package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.EstadoJustificacion;
import co.edu.uceva.microservicioplanilla.domain.model.Justificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IJustificacionRepository extends JpaRepository<Justificacion, Long> {
    List<Justificacion> findByCodigoEstudiante(Long codigoEstudiante);
    List<Justificacion> findByEventoId(Long eventoId);
    List<Justificacion> findByEstado(EstadoJustificacion estado);
    List<Justificacion> findByCodigoEstudianteAndEstado(Long codigoEstudiante, EstadoJustificacion estado);
    long countByEstado(EstadoJustificacion estado);
}
