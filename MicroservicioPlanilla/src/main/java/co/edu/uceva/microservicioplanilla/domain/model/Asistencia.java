package co.edu.uceva.microservicioplanilla.domain.model;

import co.edu.uceva.microservicioplanilla.domain.converters.EncryptionConverter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
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

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "planilla_id", insertable = false, updatable = false)
    private Planilla planilla;

    @Column(name = "fecha_hora_registro", nullable = false)
    private LocalDateTime fechaHoraRegistro;

    @Column(nullable = false, columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String estado;

    @Column(columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String geolocalizacion;

    @Column(name = "datos_adicionales", columnDefinition = "TEXT")
    @Convert(converter = EncryptionConverter.class)
    private String datosAdicionales;
}
