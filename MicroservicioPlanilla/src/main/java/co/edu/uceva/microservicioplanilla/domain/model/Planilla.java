package co.edu.uceva.microservicioplanilla.domain.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Planilla {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_origen")
    private Origen origen;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_evento")
    private Evento evento;

    @Column(name = "url_referencia", columnDefinition = "TEXT")
    private String urlReferencia;

    @Column(name = "qr_url", columnDefinition = "TEXT")
    private String qrUrl;

    @OneToMany(mappedBy = "planilla", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Campo> campos;

    @OneToMany(mappedBy = "planilla", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Fila> filas;
}