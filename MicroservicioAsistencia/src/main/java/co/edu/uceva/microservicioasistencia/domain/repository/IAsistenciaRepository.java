package co.edu.uceva.microservicioasistencia.domain.repository;

import co.edu.uceva.microservicioasistencia.domain.model.Asistencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IAsistenciaRepository extends JpaRepository<Asistencia, Long> {

    List<Asistencia> findByCodigoEstudiante(String codigoEstudiante);

    List<Asistencia> findByPlanillaId(Long planillaId);

    List<Asistencia> findByCodigoEstudianteAndPlanillaId(String codigoEstudiante, Long planillaId);

    List<Asistencia> findByFechaHoraRegistroBetween(LocalDateTime inicio, LocalDateTime fin);

    // ← ESTE MÉTODO USA EL CAMPO estado
    @Query("SELECT a FROM Asistencia a WHERE a.planillaId = :planillaId AND a.estado = 'PRESENTE'")
    List<Asistencia> findPresentesByPlanilla(@Param("planillaId") Long planillaId);
}