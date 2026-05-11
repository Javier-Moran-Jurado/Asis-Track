package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PlanillaDigitalizadaResponse {
    private Integer planillaId;
    private String imagenReferenciaB64;
    private Integer paginaNumero;
    private List<FilaDigitalizadaResponse> filas;
}
