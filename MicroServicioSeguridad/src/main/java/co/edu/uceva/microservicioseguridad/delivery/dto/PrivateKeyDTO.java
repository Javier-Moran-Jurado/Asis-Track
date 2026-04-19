package co.edu.uceva.microservicioseguridad.delivery.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.io.Serializable;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PrivateKeyDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private String privateD;
    private String publicN;
}
