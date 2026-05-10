package co.edu.uceva.microservicioplanilla.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "datos",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_dato_campo_fila_posicion",
                columnNames = {"id_campo", "id_fila", "posicion"}
        ))
@Getter
@Setter
@NoArgsConstructor
public class Dato {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_campo", nullable = false)
    private Campo campo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_fila", nullable = false)
    private Fila fila;

    @Column(nullable = false)
    private Integer posicion;

    @Column(columnDefinition = "TEXT")
    private String informacion;
}
