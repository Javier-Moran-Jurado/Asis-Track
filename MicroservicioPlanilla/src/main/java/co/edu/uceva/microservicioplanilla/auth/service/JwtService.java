package co.edu.uceva.microservicioplanilla.auth.service;


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
    @Value("${app.security.jwt.secret-key}")
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

    public boolean isTokenValid(String token) {
        return !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }



    private SecretKey getSingInKey(){
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
