package co.edu.uceva.microserviciojustificacion.auth.config;

import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import co.edu.uceva.microserviciojustificacion.domain.service.PrivateKeyResponseDTO;
import co.edu.uceva.microserviciojustificacion.domain.service.SecurityIntegrationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
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

    public DecryptionRequestBodyAdvice(SecurityIntegrationService securityIntegrationService, ObjectMapper objectMapper) {
        this.securityIntegrationService = securityIntegrationService;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
        String path = methodParameter.getExecutable().getName();
        return !path.equals("receiveClientSessionKey");
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, MethodParameter parameter, Type targetType,
                                           Class<? extends HttpMessageConverter<?>> converterType) throws IOException {
        
        try (InputStream is = inputMessage.getBody()) {
            byte[] bodyBytes = is.readAllBytes();
            if (bodyBytes.length == 0) return inputMessage;

            String bodyStr = new String(bodyBytes, StandardCharsets.UTF_8);
            
            try {
                EncryptedRequest encryptedRequest = objectMapper.readValue(bodyStr, EncryptedRequest.class);
                if (encryptedRequest.getEncryptedData() != null) {
                    PrivateKeyResponseDTO keyDto = securityIntegrationService.fetchCurrentPrivateKey();
                    RSAPrivateKey privateKey = new RSAPrivateKey(
                            new BigInteger(keyDto.getPublicN()),
                            new BigInteger(keyDto.getPrivateD())
                    );

                    String decryptedJson = RSAEncryption.decrypt(privateKey, encryptedRequest.getEncryptedData());
                    
                    return new DecryptedInputMessage(inputMessage, decryptedJson.getBytes(StandardCharsets.UTF_8));
                }
            } catch (Exception e) {
                return new DecryptedInputMessage(inputMessage, bodyBytes);
            }
        }
        return inputMessage;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
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
