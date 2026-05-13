package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class InvitadoFilaRequest {
    @Valid
    private List<InvitadoDatoRequest> datos;
}
