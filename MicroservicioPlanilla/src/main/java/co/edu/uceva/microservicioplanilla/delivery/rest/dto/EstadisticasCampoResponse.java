package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EstadisticasCampoResponse {
    private String campo;
    private String tipoCampo;
    private int totalRegistros;
    private int conRespuestas;
    private int sinRespuestas;
    private Object estadisticas;
}
