package co.edu.uceva.microservicioplanilla.domain.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "filas",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_fila_planilla_indice",
                columnNames = {"id_planilla", "indice"}
        ))
@Getter
@Setter
@NoArgsConstructor
public class Fila {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "codigo_usuario")
    private Long codigoUsuario;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_planilla", nullable = false)
    private Planilla planilla;

    @Column(nullable = false)
    private Integer indice;

    @Column(name = "fecha_registro", nullable = false, updatable = false)
    private LocalDateTime fechaRegistro;

    @OneToMany(mappedBy = "fila", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Dato> datos;

    @PrePersist
    protected void onCreate() {
        this.fechaRegistro = LocalDateTime.now();
    }
}
