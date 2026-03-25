package co.edu.uceva.microservicioplanilla.domain.model;

import jakarta.persistence.*;
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