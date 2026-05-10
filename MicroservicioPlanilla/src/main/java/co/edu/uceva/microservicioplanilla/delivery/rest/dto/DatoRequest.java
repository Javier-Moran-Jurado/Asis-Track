package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DatoRequest {
    @NotNull
    private Long campoId;

    @NotNull
    private Integer indice;

    @NotNull
    private Integer posicion;

    private String informacion;
}
