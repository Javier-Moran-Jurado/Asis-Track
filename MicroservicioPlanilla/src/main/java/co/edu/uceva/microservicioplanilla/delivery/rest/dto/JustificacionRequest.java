package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import lombok.Data;

@Data
public class JustificacionRequest {
    private Long eventoId;
    private Long codigoEstudiante;
    private String motivo;
    private String documentoUrl;
}
