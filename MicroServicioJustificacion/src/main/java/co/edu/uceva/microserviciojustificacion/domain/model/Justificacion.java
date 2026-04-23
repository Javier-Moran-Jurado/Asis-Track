package co.edu.uceva.microserviciojustificacion.domain.model;

import co.edu.uceva.microserviciojustificacion.domain.converters.EncryptionConverter;
import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "justificaciones")
@Data
public class Justificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "registro_id", nullable = false)
    private Long registroId;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String motivo;

    @Column(name = "documento_url", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String documentoUrl;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String estado; // PENDIENTE, APROBADO, RECHAZADO

    @Column(name = "usuario_codigo", nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String usuarioCodigo;

    @Column(name = "fecha_solicitud", nullable = false)
    private LocalDateTime fechaSolicitud;

    @Column(name = "fecha_revision")
    private LocalDateTime fechaRevision;

    @Column(name = "revisado_por", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String revisadoPor;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String observaciones;
}