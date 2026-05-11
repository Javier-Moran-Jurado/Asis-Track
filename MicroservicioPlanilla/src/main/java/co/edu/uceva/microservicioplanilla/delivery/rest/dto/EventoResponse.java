package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class EventoResponse {
    private Long id;
    private String nombre;
    private String descripcion;
    private LugarResponse lugar;
    private Long codigoUsuario;
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
    private LocalDateTime fechaCreacion;
    private List<PlanillaResponse> planillas;

    public static EventoResponse from(Evento entity) {
        EventoResponse dto = new EventoResponse();
        dto.setId(entity.getId());
        dto.setNombre(entity.getNombre());
        dto.setDescripcion(entity.getDescripcion());
        dto.setLugar(entity.getLugar() != null ? LugarResponse.from(entity.getLugar()) : null);
        dto.setCodigoUsuario(entity.getCodigoUsuario());
        dto.setFechaHoraInicio(entity.getFechaHoraInicio());
        dto.setFechaHoraFin(entity.getFechaHoraFin());
        dto.setFechaCreacion(entity.getFechaCreacion());
        return dto;
    }

    public static EventoResponse from(Evento entity, List<Planilla> planillas) {
        EventoResponse dto = from(entity);
        if (planillas != null) {
            dto.setPlanillas(planillas.stream().map(PlanillaResponse::from).toList());
        }
        return dto;
    }
}
