package co.edu.uceva.microserviciousuario.domain.service;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PrivateKeyResponseDTO {
    private Long id;
    private String privateD;
    private String publicN;
}
