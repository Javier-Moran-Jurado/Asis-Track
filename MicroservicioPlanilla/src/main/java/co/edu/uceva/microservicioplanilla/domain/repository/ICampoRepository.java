package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ICampoRepository extends JpaRepository<Campo, Long> {
    List<Campo> findByPlanillaId(Long planillaId);
    List<Campo> findByTipoCampoId(Long tipoCampoId);
    Campo findByPlanillaIdAndNombreCampo(Long planillaId, String nombreCampo);
    void deleteByPlanillaId(Long planillaId);
}
