package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Campo;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CampoResponse {
    private Long id;
    private Long planillaId;
    private TipoCampoResponse tipoCampo;
    private String nombreCampo;
    private boolean obligatorio;

    public static CampoResponse from(Campo entity) {
        CampoResponse dto = new CampoResponse();
        dto.setId(entity.getId());
        dto.setPlanillaId(entity.getPlanilla() != null ? entity.getPlanilla().getId() : null);
        dto.setTipoCampo(entity.getTipoCampo() != null ? TipoCampoResponse.from(entity.getTipoCampo()) : null);
        dto.setNombreCampo(entity.getNombreCampo());
        dto.setObligatorio(entity.isObligatorio());
        return dto;
    }
}
