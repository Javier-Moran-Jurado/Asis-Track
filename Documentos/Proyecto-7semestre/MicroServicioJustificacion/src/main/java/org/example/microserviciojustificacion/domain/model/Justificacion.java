package org.example.microserviciojustificacion.domain.model;

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
    private String motivo;

    @Column(name = "documento_url", columnDefinition = "TEXT")
    private String documentoUrl;

    @Column(nullable = false, length = 20)
    private String estado; // PENDIENTE, APROBADO, RECHAZADO

    @Column(name = "usuario_codigo", nullable = false, length = 50)
    private String usuarioCodigo;

    @Column(name = "fecha_solicitud", nullable = false)
    private LocalDateTime fechaSolicitud;

    @Column(name = "fecha_revision")
    private LocalDateTime fechaRevision;

    @Column(name = "revisado_por", length = 50)
    private String revisadoPor;

    @Column(columnDefinition = "TEXT")
    private String observaciones;
}