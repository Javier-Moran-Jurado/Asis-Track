package co.edu.uceva.microservicioplanilla.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "opciones_campo")
@Getter
@Setter
@NoArgsConstructor
public class OpcionesCampo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_campo", nullable = false)
    private Campo campo;

    @Column(nullable = false)
    private String valor;

    @Column(nullable = false)
    private Integer orden;
}
