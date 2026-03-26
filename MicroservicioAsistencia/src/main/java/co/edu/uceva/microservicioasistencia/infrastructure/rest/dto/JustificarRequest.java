package co.edu.uceva.microservicioasistencia.infrastructure.rest.dto;

import lombok.Data;

@Data
public class JustificarRequest {
    private String justificacion;
    private String datosAdicionales;
}