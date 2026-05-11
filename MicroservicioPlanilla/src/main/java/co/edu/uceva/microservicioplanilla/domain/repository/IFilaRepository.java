package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IFilaRepository extends JpaRepository<Fila, Long> {

    List<Fila> findByPlanillaId(Long planillaId);

    List<Fila> findByCodigoUsuario(Long codigoUsuario);

    Optional<Fila> findByPlanillaIdAndIndice(Long planillaId, Integer indice);

    @Modifying
    @Query("DELETE FROM Fila f WHERE f.planilla.id = :planillaId")
    void deleteByPlanillaId(@Param("planillaId") Long planillaId);

    @Query("SELECT MAX(f.indice) FROM Fila f WHERE f.planilla.id = :planillaId")
    Integer findMaxIndiceByPlanillaId(@Param("planillaId") Long planillaId);
}
