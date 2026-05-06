package co.edu.uceva.microservicioplanilla.domain.model;

import co.edu.uceva.microservicioplanilla.domain.converters.EncryptionConverter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.ConstraintMode;
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

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "registro_id",
            insertable = false,
            updatable = false,
            foreignKey = @ForeignKey(ConstraintMode.NO_CONSTRAINT)
    )
    private Asistencia asistencia;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String motivo;

    @Column(name = "documento_url", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String documentoUrl;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String estado;

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
