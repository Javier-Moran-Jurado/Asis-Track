package co.edu.uceva.microservicioasistencia.domain.model;

import co.edu.uceva.microservicioasistencia.domain.converters.EncryptionConverter;
import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "asistencias")
@Data
public class Asistencia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "codigo_estudiante", nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String codigoEstudiante;

    @Column(name = "planilla_id", nullable = false)
    private Long planillaId;

    @Column(name = "fecha_hora_registro", nullable = false)
    private LocalDateTime fechaHoraRegistro;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String estado; // PRESENTE, AUSENTE, TARDANZA, SALIDA, JUSTIFICADO

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String geolocalizacion;

    @Column(name = "datos_adicionales", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String datosAdicionales;
}