package co.edu.uceva.microservicioplanilla.auth.controller;

import co.edu.uceva.microservicioplanilla.domain.service.SecurityIntegrationService;
import co.edu.uceva.microservicioplanilla.domain.service.PrivateKeyResponseDTO;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpSession;
import java.math.BigInteger;
import java.util.Base64;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final SecurityIntegrationService securityIntegrationService;
    private final ObjectMapper objectMapper;

    public AuthController(SecurityIntegrationService securityIntegrationService, ObjectMapper objectMapper) {
        this.securityIntegrationService = securityIntegrationService;
        this.objectMapper = objectMapper;
    }

    @PostMapping("/session-key")
    public ResponseEntity<?> receiveClientSessionKey(@RequestBody SessionKeyRequest request, HttpSession session) {
        try {
            PrivateKeyResponseDTO serverPrivateKeyDto = securityIntegrationService.fetchCurrentPrivateKey();
            RSAPrivateKey serverPrivateKey = new RSAPrivateKey(
                    new BigInteger(serverPrivateKeyDto.getPublicN()),
                    new BigInteger(serverPrivateKeyDto.getPrivateD())
            );

            String decryptedPayload = RSAEncryption.decrypt(serverPrivateKey, request.getEncryptedPayload());
            byte[] aesKey = Base64.getDecoder().decode(decryptedPayload);

            session.setAttribute("CLIENT_AES_KEY", aesKey);

            return ResponseEntity.ok(java.util.Map.of("message", "Llave de sesion AES registrada correctamente."));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Error al procesar la llave: " + e.getMessage()));
        }
    }
}
