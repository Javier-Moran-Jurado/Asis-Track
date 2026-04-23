package co.edu.uceva.microservicioasistencia.auth.config;
import co.edu.uceva.microserviciousuario.auth.controller.ClientKeyPairDTO;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPublicKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;
import lombok.*;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.*;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;
import java.math.BigInteger;
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
            if (session != null && session.getAttribute("CLIENT_PUBLIC_KEY") != null) {
                try {
                    ClientKeyPairDTO key = (ClientKeyPairDTO) session.getAttribute("CLIENT_PUBLIC_KEY");
                    RSAPublicKey pub = new RSAPublicKey(key.getE(), new BigInteger(key.getN()));
                    String encryptedData = Base64.getEncoder().encodeToString(RSAEncryption.encrypt(pub, objectMapper.writeValueAsString(body)).getBytes());
                    EncryptedResponse encryptedResponse = new EncryptedResponse(encryptedData);

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
    @Getter @AllArgsConstructor public static class EncryptedResponse { private String encryptedData; }
}
