package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IDatoRepository extends JpaRepository<Dato, Long> {

    List<Dato> findByCampoId(Long campoId);

    @Query("SELECT d FROM Dato d WHERE d.fila.planilla.id = :planillaId")
    List<Dato> findByPlanillaId(@Param("planillaId") Long planillaId);

    @Query("SELECT d FROM Dato d WHERE d.fila.planilla.id = :planillaId AND d.fila.indice = :indice")
    List<Dato> findByPlanillaIdAndIndice(@Param("planillaId") Long planillaId, @Param("indice") Integer indice);

    Optional<Dato> findByCampoIdAndFilaIdAndPosicion(Long campoId, Long filaId, Integer posicion);

    boolean existsByCampoIdAndFilaIdAndPosicion(Long campoId, Long filaId, Integer posicion);

    @Modifying
    @Query("DELETE FROM Dato d WHERE d.fila.id = :filaId")
    void deleteByFilaId(@Param("filaId") Long filaId);

    @Modifying
    @Query("DELETE FROM Dato d WHERE d.fila.planilla.id = :planillaId")
    void deleteByPlanillaId(@Param("planillaId") Long planillaId);

    @Query("""
            SELECT d FROM Dato d
            JOIN d.campo c
            JOIN c.planilla p
            WHERE p.evento.id = :eventoId
            AND c.nombreCampo = :nombreCampo
            AND c.tipoCampo.tipo NOT IN ('signature_file', 'file')
            """)
    List<Dato> findByEventoIdAndNombreCampo(
            @Param("eventoId") Long eventoId,
            @Param("nombreCampo") String nombreCampo);

    @Query("""
            SELECT d FROM Dato d
            JOIN d.campo c
            JOIN c.planilla p
            WHERE p.evento.id = :eventoId
            AND c.tipoCampo.tipo NOT IN ('signature_file', 'file')
            """)
    List<Dato> findDatosByEventoId(@Param("eventoId") Long eventoId);
}
