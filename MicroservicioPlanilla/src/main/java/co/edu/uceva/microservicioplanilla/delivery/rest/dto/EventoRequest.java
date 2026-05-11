package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class EventoRequest {
    private String nombre;
    private String descripcion;
    private Long lugarId;
    private Long codigoUsuario;
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
}
