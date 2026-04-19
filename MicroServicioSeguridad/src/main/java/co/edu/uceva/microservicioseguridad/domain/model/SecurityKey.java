package co.edu.uceva.microservicioseguridad.domain.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class SecurityKey {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Public Key components
    @Column(columnDefinition = "TEXT")
    private String publicN;

    private Long publicE;

    // Private Key component (encrypted)
    @Column(columnDefinition = "TEXT")
    private String encryptedPrivateD;

    private LocalDateTime createdAt;

    private boolean active;
}
