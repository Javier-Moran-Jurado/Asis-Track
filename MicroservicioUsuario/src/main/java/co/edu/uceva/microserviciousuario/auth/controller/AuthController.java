package co.edu.uceva.microserviciousuario.auth.controller;

import co.edu.uceva.microserviciousuario.auth.service.AuthService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpSession;
import co.edu.uceva.microserviciousuario.domain.service.SecurityIntegrationService;
import co.edu.uceva.microserviciousuario.domain.service.PrivateKeyResponseDTO;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigInteger;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService service;
    private final SecurityIntegrationService securityIntegrationService;
    private final ObjectMapper objectMapper;

    public AuthController(AuthService service, SecurityIntegrationService securityIntegrationService, ObjectMapper objectMapper) {
        this.service = service;
        this.securityIntegrationService = securityIntegrationService;
        this.objectMapper = objectMapper;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> authenticate(@RequestBody final LoginRequest request) {
        final TokenResponse token = service.login(request);
        return ResponseEntity.ok(token);
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

            // 2. Desencriptar el payload enviado por el cliente
            String decryptedPayload = RSAEncryption.decrypt(serverPrivateKey, request.getEncryptedPayload());

            // 3. Mapear el JSON desencriptado para obtener la llave publica del cliente
            ClientKeyPairDTO clientKey = objectMapper.readValue(decryptedPayload, ClientKeyPairDTO.class);

            // 4. Guardar en Session de Redis
            session.setAttribute("CLIENT_PUBLIC_KEY", clientKey);

            return ResponseEntity.ok("Llave de sesion registrada correctamente.");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Error al procesar la llave: " + e.getMessage());
        }
    }
}