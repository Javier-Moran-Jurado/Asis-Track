package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CampoRequest {
    @NotNull
    private Long planillaId;

    @NotNull
    private Long tipoCampoId;

    @NotBlank
    private String nombreCampo;

    private List<String> opciones;
}
