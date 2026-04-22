package co.edu.uceva.microservicioasistencia.auth.repository;



import jakarta.persistence.*;
import lombok.*;

@Data
@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "tokens")
public class Token {

    public enum TokenType {
        BEARER
    }

    @Id
    @GeneratedValue
    public Long id;

    @Column(unique = true)
    public String token;

    @Enumerated(EnumType.STRING)
    public TokenType tokenType = TokenType.BEARER;

    public boolean revoked;

    public boolean expired;

    @Column(name = "codigo")
    public Long codigo;
}
