package co.edu.uceva.microservicioasistencia.domain.service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.cache.annotation.Cacheable;
@Service
public class SecurityIntegrationService {
    @Value("${app.security.integration.url}") private String securityUrl;
    @Value("${app.security.integration.secret}") private String internalSecret;
    private final RestTemplate restTemplate = new RestTemplate();
    @Cacheable(value = "securityKeys", key = "'active_private'")
    public PrivateKeyResponseDTO fetchCurrentPrivateKey() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Secret", internalSecret);
        return restTemplate.exchange(securityUrl + "/api/v1/security/keys/private", HttpMethod.GET, new HttpEntity<>(headers), PrivateKeyResponseDTO.class).getBody();
    }
    @Cacheable(value = "securityKeys", key = "'active_public'")
    public PublicKeyResponseDTO fetchCurrentPublicKey() {
        return restTemplate.exchange(securityUrl + "/api/v1/security/keys/public", HttpMethod.GET, null, PublicKeyResponseDTO.class).getBody();
    }
    @Cacheable(value = "securityKeys", key = "'private_' + #id")
    public PrivateKeyResponseDTO fetchPrivateKeyById(Long id) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Secret", internalSecret);
        return restTemplate.exchange(securityUrl + "/api/v1/security/keys/private/" + id, HttpMethod.GET, new HttpEntity<>(headers), PrivateKeyResponseDTO.class).getBody();
    }
}
