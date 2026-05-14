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
    private String nombreEvento;
    private String urlReferencia;
    private String qrUrl;
    private String eventoCoordenadas;
    private String eventoLugarNombre;
    private List<CampoResponse> campos;
    private List<FilaResponse> filas;

    public static PlanillaResponse from(Planilla entity) {
        PlanillaResponse dto = new PlanillaResponse();
        dto.setId(entity.getId());
        dto.setOrigen(entity.getOrigen() != null ? OrigenResponse.from(entity.getOrigen()) : null);
        dto.setEventoId(entity.getEvento() != null ? entity.getEvento().getId() : null);
        dto.setNombreEvento(entity.getEvento() != null ? entity.getEvento().getNombre() : null);
        
        if (entity.getEvento() != null && entity.getEvento().getLugar() != null) {
            dto.setEventoCoordenadas(entity.getEvento().getLugar().getCoordenadas());
            dto.setEventoLugarNombre(entity.getEvento().getLugar().getNombre());
        }
        
        dto.setUrlReferencia(entity.getUrlReferencia());
        dto.setQrUrl(entity.getQrUrl());
        if (entity.getCampos() != null) {
            dto.setCampos(entity.getCampos().stream().map(CampoResponse::from).toList());
        }
        if (entity.getFilas() != null) {
            dto.setFilas(entity.getFilas().stream().map(FilaResponse::from).toList());
        }
        return dto;
    }
}
