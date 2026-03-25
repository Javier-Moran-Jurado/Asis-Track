package co.edu.uceva.microservicioreporte.auth.service;

import co.edu.uceva.microservicioreporte.domain.model.UsuarioSecure;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {
    @Value("${app.security.jwt.secrect-key}")
    private  String secretKey;

    @Value("${app.security.jwt.expiration}")
    private long jwtExpiration;

    @Value("${app.security.jwt.refresh-token.expiration}")
    private long jwtRefreshExpiration;

    public Long extractCodigo(final String token){
        final Claims jwtToken = Jwts.parser()
                .verifyWith(getSingInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return Long.parseLong(jwtToken.getId());
    }

    public String extractRol(final String token){
        return Jwts.parser()
                .verifyWith(getSingInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload().get("rol").toString();
    }

    private Date extractExpiration(String token) {
        return Jwts.parser()
                .verifyWith(getSingInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getExpiration();
    }

    public boolean isTokenValid(String token, UsuarioSecure usuario) {
        final Long codigo = extractCodigo(token);
        return (codigo.equals(usuario.getCodigo())) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public String generateToken(final UsuarioSecure usuario){
        return buildToken(usuario, jwtExpiration);
    }

    public String generateRefreshToken(final UsuarioSecure usuario){
        return buildToken(usuario, jwtRefreshExpiration);
    }

    private String buildToken (final UsuarioSecure usuario, final long expiration){
        return Jwts.builder()
                .id(usuario.getCodigo().toString())
                .claims(Map.of(
                "nombre_completo", usuario.getNombreCompleto(),
                "rol", usuario.getRol()
                ))
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(getSingInKey())
                .compact();
    }

    private SecretKey getSingInKey(){
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
