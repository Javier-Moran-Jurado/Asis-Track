package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RangoEstadisticaResponse {
    private Double min;
    private Double max;
    private Long frecuencia;
    private String etiqueta;
}
