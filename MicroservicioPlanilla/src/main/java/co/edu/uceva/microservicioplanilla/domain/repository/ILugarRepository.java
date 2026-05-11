package co.edu.uceva.microservicioplanilla.domain.repository;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ILugarRepository extends JpaRepository<Lugar, Long> {
    List<Lugar> findByNombreContainingIgnoreCase(String nombre);
}
