package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.TipoCampo;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TipoCampoResponse {
    private Long id;
    private String tipo;

    public static TipoCampoResponse from(TipoCampo entity) {
        TipoCampoResponse dto = new TipoCampoResponse();
        dto.setId(entity.getId());
        dto.setTipo(entity.getTipo());
        return dto;
    }
}
