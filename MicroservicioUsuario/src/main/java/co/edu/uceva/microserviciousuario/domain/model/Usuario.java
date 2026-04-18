package co.edu.uceva.microserviciousuario.domain.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class Usuario {
    @Id
    private Long codigo;
    @NotEmpty(message = "No puede estar vacio")
    @Size(min = 2, max = 30)
    @Column(nullable = false)
    private String nombreCompleto;
    @NotEmpty(message = "No puede estar vacio")
    @Size(max = 255)
    @Column(nullable = false)
    @Email(message = "Debe ser un correo valido example@some.com")
    private String correo;
    @NotEmpty(message = "No puede estar vacio")
    @Size(min = 8, max = 255)
    @Column(nullable = false)
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[#$@!%&*-_?])[A-Za-z\\d#$@!%&*-_?]{8,}$",
            message = "La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial (#$@!%&*-_?)"
    )
    private String contrasena;
    @Min(value = 0, message = "No puede ser negativo")
    @NotNull(message = "Su cedula no puede quedar sin un valor.")
    @Column(nullable = false)
    private Long cedula;
    @NotNull(message = "Su numero de telefono no puede quedar sin un valor.")
    @Column(nullable = false)
    private Long telefono;
    @NotEmpty(message = "No puede estar vacio")
    @Pattern(
            regexp = "^(Estudiante|Coordinador|Docente|Administrativo|Decano|Rector|Administrador|Monitor|Directivo)$",
            message = "El rol debe ser uno de los siguientes: Estudiante, Docente, Coordinador, Administrativo, Decano, Rector, Monitor, Directivo o Administrador"
    )
    private String rol;
}