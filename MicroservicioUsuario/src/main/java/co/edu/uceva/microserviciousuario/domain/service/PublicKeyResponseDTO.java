package co.edu.uceva.microserviciousuario.domain.service;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.io.Serializable;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PublicKeyResponseDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private String publicN;
    private Long publicE;
}
