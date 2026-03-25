package co.edu.uceva.microserviciojustificacion.infrastructure.rest.dto;

import lombok.Data;

@Data
public class RevisionRequest {
    private String revisadoPor;
    private String observaciones;
}
