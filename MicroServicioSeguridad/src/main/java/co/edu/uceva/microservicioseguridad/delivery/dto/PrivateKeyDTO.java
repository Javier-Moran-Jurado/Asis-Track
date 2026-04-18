package co.edu.uceva.microservicioseguridad.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PrivateKeyDTO {
    private Long id;
    private String privateD;
    private String publicN;
}
