package co.edu.uceva.microservicioplanilla.domain.model;

import co.edu.uceva.microservicioplanilla.domain.converters.EncryptionConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "justificaciones")
@Getter
@Setter
@NoArgsConstructor
public class Justificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_evento", nullable = false)
    private Evento evento;

    // Referencias lógicas — Usuario vive en MicroservicioUsuario
    @Column(name = "codigo_decano")
    private Long codigoDecano;

    @Column(name = "codigo_estudiante")
    private Long codigoEstudiante;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String motivo;

    @Column(name = "documento_url", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String documentoUrl;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private EstadoJustificacion estado;

    @Column(name = "fecha_solicitud", nullable = false)
    private LocalDateTime fechaSolicitud;

    @Column(name = "fecha_revision")
    private LocalDateTime fechaRevision;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String observaciones;
}
