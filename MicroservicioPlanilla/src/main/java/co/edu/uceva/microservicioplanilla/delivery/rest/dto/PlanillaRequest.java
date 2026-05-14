package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PlanillaRequest {
    @NotNull
    private Long origenId;
    private Long eventoId;
    private String urlReferencia;
    private String qrUrl;
}
