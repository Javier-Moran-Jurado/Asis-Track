package co.edu.uceva.microservicioplanilla.domain.model;
//solucionerror
import co.edu.uceva.microservicioplanilla.domain.converters.PlanillaHomomorphicConverter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
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

    @JsonIgnore
    @OneToMany(mappedBy = "planilla", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Campo> campos;




    // --- Campos legacy: mantenidos temporalmente para backward compatibility ---
    // TODO: eliminar después de migración de datos completada (Fase 4.10)

    @Deprecated
    private LocalDateTime fechaHoraInicio;

    @Deprecated
    private LocalDateTime fechaHoraFin;

    @Deprecated
    @Column(columnDefinition = "TEXT")
    @Convert(converter = PlanillaHomomorphicConverter.class)
    private String lugar;

    @Deprecated
    @Column(columnDefinition = "TEXT")
    @Convert(converter = PlanillaHomomorphicConverter.class)
    private String metadatos;

    @Deprecated
    @Column(columnDefinition = "TEXT")
    private String estructuraMetadata;

    @Deprecated
    private LocalDateTime fechaCreacion;
}