package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.EstadoJustificacion;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class JustificacionDTO {
    private Long id;
    private Long eventoId;
    private Long codigoEstudiante;
    private Long codigoDecano;
    private String motivo;
    private String documentoUrl;
    private EstadoJustificacion estado;
    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaRevision;
    private String observaciones;
}
