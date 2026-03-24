package org.example.microservicioasistencia.domain.repository;

import org.example.microservicioasistencia.domain.model.UsuarioSecure;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUsuarioSecureRepository extends JpaRepository<UsuarioSecure, Long> {
}
