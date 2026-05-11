package co.edu.uceva.microservicioplanilla.delivery.rest.dto;

import co.edu.uceva.microservicioplanilla.domain.model.Fila;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class FilaResponse {
    private Long id;
    private Long planillaId;
    private Long codigoUsuario;
    private Integer indice;
    private LocalDateTime fechaRegistro;
    private List<DatoResponse> datos;

    public static FilaResponse from(Fila entity) {
        FilaResponse dto = new FilaResponse();
        dto.setId(entity.getId());
        dto.setPlanillaId(entity.getPlanilla() != null ? entity.getPlanilla().getId() : null);
        dto.setCodigoUsuario(entity.getCodigoUsuario());
        dto.setIndice(entity.getIndice());
        dto.setFechaRegistro(entity.getFechaRegistro());
        if (entity.getDatos() != null) {
            dto.setDatos(entity.getDatos().stream().map(DatoResponse::from).toList());
        }
        return dto;
    }
}
