package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class FilaResponse {
    private Long id;
    private Long planillaId;
    private Long codigoUsuario;
    private Integer indice;
    private LocalDateTime fechaRegistro;
    private List<DatoResponse> datos;
}
