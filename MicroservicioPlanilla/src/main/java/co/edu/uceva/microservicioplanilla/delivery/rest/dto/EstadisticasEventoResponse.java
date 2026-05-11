package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class EstadisticasEventoResponse {
    private Long eventoId;
    private String nombreEvento;
    private int totalPlanillas;
    private int totalFilas;
    private List<EstadisticasCampoResponse> campos;
}
