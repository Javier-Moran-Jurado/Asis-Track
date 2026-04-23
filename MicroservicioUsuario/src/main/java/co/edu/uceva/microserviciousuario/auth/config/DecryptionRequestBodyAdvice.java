package co.edu.uceva.microserviciousuario.auth.config;

import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import co.edu.uceva.microserviciousuario.domain.service.PrivateKeyResponseDTO;
import co.edu.uceva.microserviciousuario.domain.service.SecurityIntegrationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.*;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestBodyAdviceAdapter;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;

@ControllerAdvice
public class DecryptionRequestBodyAdvice extends RequestBodyAdviceAdapter {

    private final SecurityIntegrationService securityIntegrationService;
    private final ObjectMapper objectMapper;

    public DecryptionRequestBodyAdvice(SecurityIntegrationService securityIntegrationService,
            ObjectMapper objectMapper) {
        this.securityIntegrationService = securityIntegrationService;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType,
            Class<? extends HttpMessageConverter<?>> converterType) {
        // Solo interceptar si el endpoint espera un objeto complejo (no para el
        // registro de llave inicial)
        String path = methodParameter.getExecutable().getName();
        return !path.equals("receiveClientSessionKey");
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, MethodParameter parameter, Type targetType,
            Class<? extends HttpMessageConverter<?>> converterType) throws IOException {

        try (InputStream is = inputMessage.getBody()) {
            byte[] bodyBytes = is.readAllBytes();
            if (bodyBytes.length == 0)
                return inputMessage;

            String bodyStr = new String(bodyBytes, StandardCharsets.UTF_8);

            // Intentar mapear a EncryptedRequest
            try {
                EncryptedRequest encryptedRequest = objectMapper.readValue(bodyStr, EncryptedRequest.class);
                if (encryptedRequest.getEncryptedData() != null) {
                    // 1. Obtener llave privada del servidor
                    PrivateKeyResponseDTO keyDto = securityIntegrationService.fetchCurrentPrivateKey();
                    RSAPrivateKey privateKey = new RSAPrivateKey(
                            new BigInteger(keyDto.getPublicN()),
                            new BigInteger(keyDto.getPrivateD()));

                    // 2. Desencriptar
                    String decryptedJson = RSAEncryption.decrypt(privateKey, encryptedRequest.getEncryptedData());
                    System.out.println("[*] Decrypted JSON: " + decryptedJson);

                    return new DecryptedInputMessage(inputMessage, decryptedJson.getBytes(StandardCharsets.UTF_8));
                }
            } catch (Exception e) {
                System.err.println("[!] Decryption error: " + e.getMessage());
                // No es necesario el printStackTrace si es solo un campo faltante
                return new DecryptedInputMessage(inputMessage, bodyBytes);
            }
            // Si llegamos aquí es porque encryptedRequest.getEncryptedData() era null
            return new DecryptedInputMessage(inputMessage, bodyBytes);
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Data
    public static class EncryptedRequest {
        private String encryptedData;
    }

    private static class DecryptedInputMessage implements HttpInputMessage {
        private final HttpInputMessage original;
        private final byte[] body;

        public DecryptedInputMessage(HttpInputMessage original, byte[] body) {
            this.original = original;
            this.body = body;
        }

        @Override
        public InputStream getBody() {
            return new ByteArrayInputStream(body);
        }

        @Override
        public org.springframework.http.HttpHeaders getHeaders() {
            return original.getHeaders();
        }
    }
}
