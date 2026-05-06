package co.edu.uceva.microservicioplanilla.delibery.rest.dto;

import lombok.Data;

import java.time.LocalDateTime;

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
