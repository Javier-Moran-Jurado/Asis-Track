package co.edu.uceva.microserviciojustificacion.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ITokenRepository extends JpaRepository<Token, Long> {
    @Query("""
        select t from tokens_justificacion t 
        where t.codigo = :usuarioId 
        and (t.expired = false or t.revoked = false)
    """)
    List<Token> findAllValidTokensByUser(Long usuarioId);

    Optional<Token> findByToken(String token);
}
