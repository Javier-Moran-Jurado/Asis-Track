package co.edu.uceva.microservicioplanilla.domain.model;
//solucionerror
import co.edu.uceva.microservicioplanilla.domain.converters.PlanillaHomomorphicConverter;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Planilla {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = PlanillaHomomorphicConverter.class)
    private String lugar;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = PlanillaHomomorphicConverter.class)
    private String metadatos;

    private LocalDateTime fechaCreacion;
}