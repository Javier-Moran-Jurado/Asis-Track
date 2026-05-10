package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IFilaRepository extends JpaRepository<Fila, Long> {

    List<Fila> findByPlanillaId(Long planillaId);

    List<Fila> findByCodigoUsuario(Long codigoUsuario);

    Optional<Fila> findByPlanillaIdAndIndice(Long planillaId, Integer indice);
}
