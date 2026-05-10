package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class GenerarPropuestaRequest {
    @NotBlank
    private String descripcion;

    private boolean crearEvento = false;

    private Long lugarId;
}
