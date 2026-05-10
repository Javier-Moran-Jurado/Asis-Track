package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DatoResponse {
    private Long id;
    private Long campoId;
    private Long filaId;
    private Integer posicion;
    private String informacion;
}
