package co.edu.uceva.microservicioasistencia.domain.model;

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

    @Column(name = "codigo_estudiante", nullable = false, length = 50)
    private String codigoEstudiante;

    @Column(name = "planilla_id", nullable = false)
    private Long planillaId;

    @Column(name = "fecha_hora_registro", nullable = false)
    private LocalDateTime fechaHoraRegistro;

    @Column(nullable = false, length = 20)
    private String estado; // PRESENTE, AUSENTE, TARDANZA, SALIDA, JUSTIFICADO

    @Column(columnDefinition = "TEXT")
    private String geolocalizacion;

    @Column(name = "datos_adicionales", columnDefinition = "TEXT")
    private String datosAdicionales;
}