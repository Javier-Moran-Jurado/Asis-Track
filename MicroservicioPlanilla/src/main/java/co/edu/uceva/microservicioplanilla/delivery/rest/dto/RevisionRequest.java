package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Data;

@Data
public class RevisionRequest {
    private Long codigoDecano;
    private String observaciones;
}
