package co.edu.uceva.microserviciousuario.auth.config;

import co.uceva.edu.security.AES.AESEncryption;
import co.edu.uceva.microserviciousuario.domain.service.SecurityIntegrationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;
import lombok.*;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestBodyAdviceAdapter;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

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

            try {
                EncryptedRequest encryptedRequest = objectMapper.readValue(bodyStr, EncryptedRequest.class);
                if (encryptedRequest.getEncryptedData() != null && encryptedRequest.getIv() != null) {
                    HttpSession session = ((ServletRequestAttributes) RequestContextHolder.currentRequestAttributes()).getRequest().getSession(false);
                    if (session != null && session.getAttribute("CLIENT_AES_KEY") != null) {
                        byte[] aesKey = (byte[]) session.getAttribute("CLIENT_AES_KEY");
                        byte[] iv = Base64.getDecoder().decode(encryptedRequest.getIv());

                        String decryptedJson = AESEncryption.decrypt(aesKey, iv, encryptedRequest.getEncryptedData());

                        return new DecryptedInputMessage(inputMessage, decryptedJson.getBytes(StandardCharsets.UTF_8));
                    }
                }
            } catch (Exception e) {
                System.err.println("[!] Decryption error: " + e.getMessage());
                return new DecryptedInputMessage(inputMessage, bodyBytes);
            }
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
        private String iv;
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
