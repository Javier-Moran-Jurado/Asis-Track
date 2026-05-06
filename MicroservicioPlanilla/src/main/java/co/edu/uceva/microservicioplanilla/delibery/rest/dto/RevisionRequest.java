package co.edu.uceva.microservicioplanilla.delibery.rest.dto;

import lombok.Data;

@Data
public class RevisionRequest {
    private String revisadoPor;
    private String observaciones;
}
