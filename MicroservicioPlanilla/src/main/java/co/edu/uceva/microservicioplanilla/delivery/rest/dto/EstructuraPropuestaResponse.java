package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class EstructuraPropuestaResponse {
    private Long planillaId;
    private List<CampoPropuestoResponse> campos;
}
