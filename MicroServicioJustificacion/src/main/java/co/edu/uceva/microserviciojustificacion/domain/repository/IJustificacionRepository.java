package co.edu.uceva.microserviciojustificacion.domain.repository;

import co.edu.uceva.microserviciojustificacion.domain.model.Justificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface IJustificacionRepository extends JpaRepository<Justificacion, Long> {

    List<Justificacion> findByUsuarioCodigo(String usuarioCodigo);

    List<Justificacion> findByRegistroId(Long registroId);

    List<Justificacion> findByEstado(String estado);

    List<Justificacion> findByUsuarioCodigoAndEstado(String usuarioCodigo, String estado);
}
