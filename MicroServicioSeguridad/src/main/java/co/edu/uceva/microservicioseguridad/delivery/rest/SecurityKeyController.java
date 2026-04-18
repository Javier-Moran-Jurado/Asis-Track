package co.edu.uceva.microservicioseguridad.delivery.rest;

import co.edu.uceva.microservicioseguridad.delivery.dto.PrivateKeyDTO;
import co.edu.uceva.microservicioseguridad.delivery.dto.PublicKeyDTO;
import co.edu.uceva.microservicioseguridad.domain.service.ISecurityKeyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/security/keys")
public class SecurityKeyController {

    @Autowired
    private ISecurityKeyService securityKeyService;

    @Value("${app.security.internal-secret}")
    private String internalSecret;

    // Public endpoint for anyone
    @GetMapping("/public")
    public ResponseEntity<PublicKeyDTO> getPublicKey() {
        return ResponseEntity.ok(securityKeyService.getPublicKey());
    }

    // Protected endpoint for Microservices
    @GetMapping("/private")
    public ResponseEntity<?> getPrivateKey(@RequestHeader(value = "X-Internal-Secret", required = false) String secret) {
        if (secret == null || !secret.equals(internalSecret)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Acceso denegado: Se requiere un secreto interno valido");
        }
        return ResponseEntity.ok(securityKeyService.getPrivateKey());
    }

    // Endpoint manual para forzar rotacion (idealmente protegido por rol ADMIN o similar)
    @PostMapping("/rotate")
    @PreAuthorize("hasRole('Administrador')")
    public ResponseEntity<String> forceRotation() {
        securityKeyService.rotarLlaves();
        return ResponseEntity.ok("Llaves rotadas correctamente");
    }

    // Protected endpoint for Microservices by ID
    @GetMapping("/private/{id}")
    public ResponseEntity<?> getPrivateKeyById(@PathVariable Long id, @RequestHeader(value = "X-Internal-Secret", required = false) String secret) {
        if (secret == null || !secret.equals(internalSecret)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Acceso denegado: Se requiere un secreto interno valido");
        }
        return ResponseEntity.ok(securityKeyService.getPrivateKeyById(id));
    }
}
