package co.edu.uceva.microserviciousuario.auth.controller;

import co.edu.uceva.microserviciousuario.auth.service.AuthService;
import co.edu.uceva.microserviciousuario.auth.service.GoogleOAuthService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpSession;
import co.edu.uceva.microserviciousuario.domain.service.SecurityIntegrationService;
import co.edu.uceva.microserviciousuario.domain.service.PrivateKeyResponseDTO;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigInteger;
import java.util.Base64;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService service;
    private final GoogleOAuthService googleOAuthService;
    private final SecurityIntegrationService securityIntegrationService;
    private final ObjectMapper objectMapper;

    public AuthController(AuthService service, GoogleOAuthService googleOAuthService, SecurityIntegrationService securityIntegrationService, ObjectMapper objectMapper) {
        this.service = service;
        this.googleOAuthService = googleOAuthService;
        this.securityIntegrationService = securityIntegrationService;
        this.objectMapper = objectMapper;
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticate(@RequestBody final LoginRequest request) {
        try {
            final TokenResponse token = service.login(request);
            return ResponseEntity.ok(token);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(java.util.Map.of("message", "Código o contraseña incorrectos."));
        }
    }

    @PostMapping("/refresh")
    public TokenResponse refreshToken(@RequestHeader(HttpHeaders.AUTHORIZATION) final String authHeader) {
        return service.refreshToken(authHeader);
    }

    @PostMapping("/session-key")
    public ResponseEntity<?> receiveClientSessionKey(@RequestBody SessionKeyRequest request, HttpSession session) {
        try {
            // 1. Obtener la llave privada actual del Servidor Central de Seguridad
            PrivateKeyResponseDTO serverPrivateKeyDto = securityIntegrationService.fetchCurrentPrivateKey();
            RSAPrivateKey serverPrivateKey = new RSAPrivateKey(
                    new BigInteger(serverPrivateKeyDto.getPublicN()),
                    new BigInteger(serverPrivateKeyDto.getPrivateD())
            );

            // 2. Desencriptar el payload enviado por el cliente (contiene la clave AES en Base64)
            String decryptedPayload = RSAEncryption.decrypt(serverPrivateKey, request.getEncryptedPayload());

            // 3. El payload desencriptado es la clave AES en formato Base64
            byte[] aesKey = Base64.getDecoder().decode(decryptedPayload);

            // 4. Guardar la clave AES en la sesión de Redis
            session.setAttribute("CLIENT_AES_KEY", aesKey);

            return ResponseEntity.ok(java.util.Map.of("message", "Llave de sesion AES registrada correctamente."));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Error al procesar la llave: " + e.getMessage()));
        }
    }

    @PostMapping("/oauth2/google")
    public ResponseEntity<?> oauth2Google(@RequestBody final GoogleOAuthRequest request) {
        try {
            final TokenResponse token = googleOAuthService.authenticate(request.idToken());
            return ResponseEntity.ok(token);
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }
}
