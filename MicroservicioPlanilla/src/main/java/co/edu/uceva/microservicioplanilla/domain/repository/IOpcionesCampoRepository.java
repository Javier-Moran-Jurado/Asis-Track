package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.OpcionesCampo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IOpcionesCampoRepository extends JpaRepository<OpcionesCampo, Long> {
    List<OpcionesCampo> findByCampo_IdOrderByOrden(Long idCampo);
    void deleteByCampo_Id(Long idCampo);
}
