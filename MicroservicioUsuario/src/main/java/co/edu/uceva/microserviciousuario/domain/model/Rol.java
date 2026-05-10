package co.edu.uceva.microserviciousuario.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
public class Rol {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String nombre; // Estudiante, Coordinador, Docente, Administrativo, Decano, Rector, Administrador, Monitor, Directivo

    public Rol(String nombre) {
        this.nombre = nombre;
    }
}
