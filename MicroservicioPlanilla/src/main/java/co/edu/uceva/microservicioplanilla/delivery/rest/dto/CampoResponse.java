package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import co.edu.uceva.microservicioplanilla.domain.model.OpcionesCampo;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CampoResponse {
    private Long id;
    private Long planillaId;
    private TipoCampoResponse tipoCampo;
    private String nombreCampo;
    private boolean obligatorio;
    private List<String> opciones;

    public static CampoResponse from(Campo entity) {
        CampoResponse dto = new CampoResponse();
        dto.setId(entity.getId());
        dto.setPlanillaId(entity.getPlanilla() != null ? entity.getPlanilla().getId() : null);
        dto.setTipoCampo(entity.getTipoCampo() != null ? TipoCampoResponse.from(entity.getTipoCampo()) : null);
        dto.setNombreCampo(entity.getNombreCampo());
        dto.setObligatorio(entity.isObligatorio());
        return dto;
    }

    public static CampoResponse from(Campo entity, List<OpcionesCampo> opciones) {
        CampoResponse dto = from(entity);
        if (opciones != null) {
            dto.setOpciones(opciones.stream().map(OpcionesCampo::getValor).toList());
        }
        return dto;
    }
}
