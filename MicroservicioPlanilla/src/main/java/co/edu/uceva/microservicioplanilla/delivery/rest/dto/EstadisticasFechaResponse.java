package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EstadisticasFechaResponse {
    private int conRespuestas;
    private int sinRespuestas;
    private long valoresUnicos;
    private int totalFechas;
}
