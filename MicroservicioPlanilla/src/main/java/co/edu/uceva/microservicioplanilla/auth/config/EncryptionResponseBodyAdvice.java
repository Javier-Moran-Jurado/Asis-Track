package co.edu.uceva.microservicioplanilla.auth.config;

import co.uceva.edu.security.AES.AESEncryption;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.*;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.*;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;
import java.util.Base64;

@ControllerAdvice
public class EncryptionResponseBodyAdvice implements ResponseBodyAdvice<Object> {
    private final ObjectMapper objectMapper;
    public EncryptionResponseBodyAdvice(ObjectMapper objectMapper) { this.objectMapper = objectMapper; }
    @Override public boolean supports(MethodParameter rt, Class<? extends HttpMessageConverter<?>> ct) { return true; }
    @Override public Object beforeBodyWrite(Object body, MethodParameter rt, MediaType ct, Class<? extends HttpMessageConverter<?>> sct, ServerHttpRequest req, ServerHttpResponse res) {
        if (body == null || body instanceof EncryptedResponse) return body;
        if (req instanceof ServletServerHttpRequest sr) {
            HttpSession session = sr.getServletRequest().getSession(false);
            if (session != null && session.getAttribute("CLIENT_AES_KEY") != null) {
                try {
                    byte[] aesKey = (byte[]) session.getAttribute("CLIENT_AES_KEY");
                    byte[] iv = AESEncryption.generateIV();

                    String payload = objectMapper.writeValueAsString(body);
                    String encryptedPayload = AESEncryption.encrypt(aesKey, iv, payload);
                    String ivB64 = Base64.getEncoder().encodeToString(iv);

                    EncryptedResponse encryptedResponse = new EncryptedResponse(encryptedPayload, ivB64);

                    if (body instanceof String) {
                        res.getHeaders().setContentType(MediaType.APPLICATION_JSON);
                        return objectMapper.writeValueAsString(encryptedResponse);
                    }
                    return encryptedResponse;
                } catch (Exception e) { e.printStackTrace(); }
            }
        }
        return body;
    }
    @Getter @AllArgsConstructor public static class EncryptedResponse { private String encryptedData; private String iv; }
}
