package co.edu.uceva.microservicioreporte.domain.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "usuario")
@Getter
@Setter
public class UsuarioSecure {
    @Id
    private Long codigo;
    private String nombreCompleto;
    private String rol;
}