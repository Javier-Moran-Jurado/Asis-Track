package co.edu.uceva.microserviciojustificacion.infrastructure.rest.dto;

import lombok.Data;

@Data
public class JustificacionRequest {
    private Long registroId;
    private String usuarioCodigo;
    private String motivo;
    private String documentoUrl;
}
