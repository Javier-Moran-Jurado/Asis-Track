package co.edu.uceva.microservicioplanilla.delibery.rest.dto;

import lombok.Data;

@Data
public class JustificacionRequest {
    private Long registroId;
    private String usuarioCodigo;
    private String motivo;
    private String documentoUrl;
}
