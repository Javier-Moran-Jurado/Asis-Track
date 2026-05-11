package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class PlanillaResponse {
    private Long id;
    private OrigenResponse origen;
    private Long eventoId;
    private String urlReferencia;
    private List<CampoResponse> campos;
    private List<FilaResponse> filas;

    public static PlanillaResponse from(Planilla entity) {
        PlanillaResponse dto = new PlanillaResponse();
        dto.setId(entity.getId());
        dto.setOrigen(entity.getOrigen() != null ? OrigenResponse.from(entity.getOrigen()) : null);
        dto.setEventoId(entity.getEvento() != null ? entity.getEvento().getId() : null);
        dto.setUrlReferencia(entity.getUrlReferencia());
        if (entity.getCampos() != null) {
            dto.setCampos(entity.getCampos().stream().map(CampoResponse::from).toList());
        }
        if (entity.getFilas() != null) {
            dto.setFilas(entity.getFilas().stream().map(FilaResponse::from).toList());
        }
        return dto;
    }
}
