package co.edu.uceva.microservicioreporte.domain.model;

import co.edu.uceva.microservicioreporte.domain.converters.EncryptionConverter;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "usuario")
@Getter
@Setter
public class UsuarioSecure {
    @Id
    private Long codigo;
    @Convert(converter = EncryptionConverter.class)
    private String nombreCompleto;
    @Convert(converter = EncryptionConverter.class)
    private String rol;
}