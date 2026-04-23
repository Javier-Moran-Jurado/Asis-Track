package co.edu.uceva.microserviciojustificacion.infrastructure.rest.dto;

import java.time.LocalDateTime;

import lombok.Data;

@Data
public class JustificacionDTO {
    private String id;
    private String registroId;
    private String motivo;
    private String documentoUrl;
    private String estado;
    private String usuarioCodigo;
    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaRevision;
    private String revisadoPor;
    private String observaciones;
}