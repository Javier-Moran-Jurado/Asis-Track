package co.edu.uceva.microservicioplanilla.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "datos",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_dato_campo_indice_posicion",
                columnNames = {"id_campo", "indice", "posicion"}
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

    @Column(nullable = false)
    private Integer indice;   // fila dentro de la planilla (0-based)

    @Column(nullable = false)
    private Integer posicion; // índice dentro de una respuesta de opción múltiple (0 para campos simples)

    @Column(columnDefinition = "TEXT")
    private String informacion; // Sin cifrado global — ver decisión pendiente en el plan (Fase 4)
}
