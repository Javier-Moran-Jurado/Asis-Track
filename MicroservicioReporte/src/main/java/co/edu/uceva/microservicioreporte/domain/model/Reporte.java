package co.edu.uceva.microservicioreporte.domain.model;

import co.edu.uceva.microservicioreporte.domain.converters.EncryptionConverter;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Reporte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String tipo;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String datos;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String formato;
}