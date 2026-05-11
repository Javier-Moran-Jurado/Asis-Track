package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Origen;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class OrigenResponse {
    private Long id;
    private String origen;

    public static OrigenResponse from(Origen entity) {
        OrigenResponse dto = new OrigenResponse();
        dto.setId(entity.getId());
        dto.setOrigen(entity.getOrigen());
        return dto;
    }
}
