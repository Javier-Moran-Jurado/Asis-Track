package co.edu.uceva.microserviciousuario.domain.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class SecurityIntegrationService {

    @Value("${app.security.integration.url}")
    private String securityUrl;

    @Value("${app.security.integration.secret}")
    private String internalSecret;

    private final RestTemplate restTemplate;

    public SecurityIntegrationService() {
        this.restTemplate = new RestTemplate();
    }

    public PrivateKeyResponseDTO fetchCurrentPrivateKey() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Secret", internalSecret);
        
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        ResponseEntity<PrivateKeyResponseDTO> response = restTemplate.exchange(
                securityUrl + "/api/v1/security/keys/private",
                HttpMethod.GET,
                entity,
                PrivateKeyResponseDTO.class
        );
        
        return response.getBody();
    }
}
