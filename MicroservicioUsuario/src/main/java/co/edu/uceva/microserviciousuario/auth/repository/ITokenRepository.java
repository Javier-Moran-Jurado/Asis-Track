package co.edu.uceva.microserviciousuario.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface ITokenRepository extends JpaRepository<Token, Long> {
    @Query("""
        select t from tokens t 
        where t.usuario.codigo = :usuarioId 
        and (t.expired = false or t.revoked = false)
    """)
    List<Token> findAllValidTokensByUser(Long usuarioId);

    Optional<Token> findByToken(String token);
}
