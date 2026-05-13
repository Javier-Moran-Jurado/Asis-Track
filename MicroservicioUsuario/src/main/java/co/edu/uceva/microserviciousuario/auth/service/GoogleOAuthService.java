package co.edu.uceva.microserviciousuario.auth.service;

import co.edu.uceva.microserviciousuario.auth.controller.TokenResponse;
import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GoogleOAuthService {

    private final JwtService jwtService;
    private final IUsuarioRepository usuarioRepository;

    @Value("${app.security.oauth2.google.client-ids}")
    private String clientIds;

    private static final String GOOGLE_ISSUER_1 = "https://accounts.google.com";
    private static final String GOOGLE_ISSUER_2 = "accounts.google.com";
    private static final String ALLOWED_DOMAIN = "@uceva.edu.co";

    public TokenResponse authenticate(String idTokenString) {
        if (idTokenString == null || idTokenString.isBlank()) {
            throw new IllegalArgumentException("El idToken de Google es obligatorio.");
        }

        List<String> audience = Arrays.asList(clientIds.split(","));

        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(),
                new GsonFactory()
        )
                .setIssuers(Arrays.asList(GOOGLE_ISSUER_1, GOOGLE_ISSUER_2))
                .setAudience(audience)
                .build();

        GoogleIdToken idToken;
        try {
            idToken = verifier.verify(idTokenString);
        } catch (GeneralSecurityException | IOException e) {
            throw new IllegalArgumentException("Error al validar el token de Google: " + e.getMessage());
        }

        if (idToken == null) {
            throw new IllegalArgumentException("Token de Google invalido o expirado.");
        }

        GoogleIdToken.Payload payload = idToken.getPayload();
        String email = payload.getEmail();

        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("El token de Google no contiene un correo electronico.");
        }

        if (!email.toLowerCase().endsWith(ALLOWED_DOMAIN)) {
            throw new IllegalArgumentException("Solo se permite acceso con correo institucional (@uceva.edu.co).");
        }

        Usuario usuario = usuarioRepository.findByCorreo(email)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Usuario no registrado. Contacte al administrador."
                ));

        String jwtToken = jwtService.generateToken(usuario);
        String jwtRefreshToken = jwtService.generateRefreshToken(usuario);

        return new TokenResponse(jwtToken, jwtRefreshToken);
    }
}
