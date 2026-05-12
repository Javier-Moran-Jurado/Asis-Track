package co.edu.uceva.microservicioplanilla.auth.config;

import co.uceva.edu.security.AES.AESEncryption;
import co.edu.uceva.microservicioplanilla.domain.service.PrivateKeyResponseDTO;
import co.edu.uceva.microservicioplanilla.domain.service.SecurityIntegrationService;
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

import java.io.*;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

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
                if (req.getEncryptedData() != null && req.getIv() != null) {
                    HttpSession session = ((ServletRequestAttributes) RequestContextHolder.currentRequestAttributes()).getRequest().getSession(false);
                    if (session != null && session.getAttribute("CLIENT_AES_KEY") != null) {
                        byte[] aesKey = (byte[]) session.getAttribute("CLIENT_AES_KEY");
                        byte[] iv = Base64.getDecoder().decode(req.getIv());

                        String decryptedJson = AESEncryption.decrypt(aesKey, iv, req.getEncryptedData());
                        return new DecryptedInputMessage(im, decryptedJson.getBytes(StandardCharsets.UTF_8));
                    }
                }
            } catch (Exception e) { return new DecryptedInputMessage(im, bytes); }
            return new DecryptedInputMessage(im, bytes);
        }
    }
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor public static class EncryptedRequest { private String encryptedData; private String iv; }
    private static class DecryptedInputMessage implements HttpInputMessage {
        private final HttpInputMessage original; private final byte[] body;
        public DecryptedInputMessage(HttpInputMessage o, byte[] b) { this.original = o; this.body = b; }
        @Override public InputStream getBody() { return new ByteArrayInputStream(body); }
        @Override public org.springframework.http.HttpHeaders getHeaders() { return original.getHeaders(); }
    }
}
