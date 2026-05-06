package co.edu.uceva.microservicioplanilla.delibery.rest.dto;

import lombok.Data;

@Data
public class JustificarRequest {
    private String justificacion;
    private String datosAdicionales;
}
