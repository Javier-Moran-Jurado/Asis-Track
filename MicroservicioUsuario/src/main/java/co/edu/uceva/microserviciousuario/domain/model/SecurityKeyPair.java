package co.edu.uceva.microserviciousuario.domain.model;

import co.edu.uceva.microserviciousuario.domain.converters.RSAKeyConverter;
import co.uceva.edu.security.RSA.RSAKeyPair;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.convert.ValueConverter;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class SecurityKeyPair {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Convert(converter = RSAKeyConverter.class)
    private RSAKeyPair rsaKeyPair;
}
