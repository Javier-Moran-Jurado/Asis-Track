package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface IDatoRepository extends JpaRepository<Dato, Long> {

    List<Dato> findByCampoId(Long campoId);

    @Query("SELECT d FROM Dato d WHERE d.campo.planilla.id = :planillaId")
    List<Dato> findByPlanillaId(@Param("planillaId") Long planillaId);

    @Query("SELECT d FROM Dato d WHERE d.campo.planilla.id = :planillaId AND d.indice = :indice")
    List<Dato> findByPlanillaIdAndIndice(@Param("planillaId") Long planillaId, @Param("indice") Integer indice);

    Optional<Dato> findByCampoIdAndIndiceAndPosicion(Long campoId, Integer indice, Integer posicion);

    boolean existsByCampoIdAndIndiceAndPosicion(Long campoId, Integer indice, Integer posicion);
}
