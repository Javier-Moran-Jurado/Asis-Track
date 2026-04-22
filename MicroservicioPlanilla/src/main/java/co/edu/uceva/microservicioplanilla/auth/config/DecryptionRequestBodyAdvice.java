package co.edu.uceva.microservicioplanilla.auth.config;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import co.edu.uceva.microserviciousuario.domain.service.PrivateKeyResponseDTO;
import co.edu.uceva.microservicioplanilla.domain.service.SecurityIntegrationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.*;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestBodyAdviceAdapter;
import java.io.*;
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
    @Override public boolean supports(MethodParameter mp, Type tt, Class<? extends HttpMessageConverter<?>> ct) { return !mp.getExecutable().getName().equals("receiveClientSessionKey"); }
    @Override public HttpInputMessage beforeBodyRead(HttpInputMessage im, MethodParameter p, Type tt, Class<? extends HttpMessageConverter<?>> ct) throws IOException {
        try (InputStream is = im.getBody()) {
            byte[] bytes = is.readAllBytes();
            if (bytes.length == 0) return im;
            try {
                EncryptedRequest req = objectMapper.readValue(new String(bytes, StandardCharsets.UTF_8), EncryptedRequest.class);
                if (req.getEncryptedData() != null) {
                    PrivateKeyResponseDTO dto = securityIntegrationService.fetchCurrentPrivateKey();
                    RSAPrivateKey pk = new RSAPrivateKey(new BigInteger(dto.getPublicN()), new BigInteger(dto.getPrivateD()));
                    return new DecryptedInputMessage(im, RSAEncryption.decrypt(pk, req.getEncryptedData()).getBytes(StandardCharsets.UTF_8));
                }
            } catch (Exception e) { return new DecryptedInputMessage(im, bytes); }
        }
        return im;
    }
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor public static class EncryptedRequest { private String encryptedData; }
    private static class DecryptedInputMessage implements HttpInputMessage {
        private final HttpInputMessage original; private final byte[] body;
        public DecryptedInputMessage(HttpInputMessage o, byte[] b) { this.original = o; this.body = b; }
        @Override public InputStream getBody() { return new ByteArrayInputStream(body); }
        @Override public org.springframework.http.HttpHeaders getHeaders() { return original.getHeaders(); }
    }
}
