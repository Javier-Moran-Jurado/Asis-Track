package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class ConfirmarPropuestaRequest {
    private EventoConfirmadoRequest evento;

    @NotNull
    private List<CampoRequest> campos;
}
