package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.Map;

@Getter
@Setter
public class EstadisticasTextoResponse {
    private int conRespuestas;
    private int sinRespuestas;
    private long valoresUnicos;
    private String valorMasComun;
    private Map<String, Long> frecuencias;
    private List<String> valores;
}
