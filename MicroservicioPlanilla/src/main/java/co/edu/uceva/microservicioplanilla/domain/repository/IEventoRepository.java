package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface IEventoRepository extends JpaRepository<Evento, Long> {
    List<Evento> findByCodigoUsuario(Long codigoUsuario);
    List<Evento> findByFechaHoraInicioBetween(LocalDateTime inicio, LocalDateTime fin);
    List<Evento> findByLugarId(Long lugarId);
}
