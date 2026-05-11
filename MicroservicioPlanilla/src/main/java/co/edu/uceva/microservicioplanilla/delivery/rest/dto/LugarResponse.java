package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Lugar;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LugarResponse {
    private Long id;
    private String nombre;
    private String coordenadas;

    public static LugarResponse from(Lugar entity) {
        LugarResponse dto = new LugarResponse();
        dto.setId(entity.getId());
        dto.setNombre(entity.getNombre());
        dto.setCoordenadas(entity.getCoordenadas());
        return dto;
    }
}
