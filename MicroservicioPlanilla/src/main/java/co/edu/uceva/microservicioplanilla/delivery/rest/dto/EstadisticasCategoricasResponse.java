package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.Map;

@Getter
@Setter
public class EstadisticasCategoricasResponse {
    private int conRespuestas;
    private int sinRespuestas;
    private Map<String, Long> distribucion;
    private List<String> valores;
}
