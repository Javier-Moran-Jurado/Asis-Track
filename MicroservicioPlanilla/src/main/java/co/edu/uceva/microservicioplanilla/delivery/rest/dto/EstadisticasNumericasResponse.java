package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class EstadisticasNumericasResponse {
    private int conRespuestas;
    private int sinRespuestas;
    private Double min;
    private Double max;
    private Double promedio;
    private Double suma;
    private Long count;
    private List<RangoEstadisticaResponse> distribucionPorRango;
}
