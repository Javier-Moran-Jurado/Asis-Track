package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Dato;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DatoResponse {
    private Long id;
    private Long campoId;
    private Long filaId;
    private Integer posicion;
    private String informacion;

    public static DatoResponse from(Dato entity) {
        DatoResponse dto = new DatoResponse();
        dto.setId(entity.getId());
        dto.setCampoId(entity.getCampo() != null ? entity.getCampo().getId() : null);
        dto.setFilaId(entity.getFila() != null ? entity.getFila().getId() : null);
        dto.setPosicion(entity.getPosicion());
        dto.setInformacion(entity.getInformacion());
        return dto;
    }
}
