package co.edu.uceva.microservicioseguridad.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PublicKeyDTO {
    private Long id;
    private String publicN;
    private Long publicE;
}
