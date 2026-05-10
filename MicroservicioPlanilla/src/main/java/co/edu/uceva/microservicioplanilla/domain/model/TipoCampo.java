package co.edu.uceva.microservicioplanilla.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "tipos_de_campos")
@Getter
@Setter
@NoArgsConstructor
public class TipoCampo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String tipo; // "text", "numeric", "signature_file", "file", "date", "checkbox", "multivaluecheckbox", "combo", "radio", "e-mail", "secret"
}
