package co.edu.uceva.microserviciojustificacion.auth.config;

import co.edu.uceva.microserviciousuario.auth.controller.ClientKeyPairDTO;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAPublicKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

import java.math.BigInteger;
import java.util.Base64;

@ControllerAdvice
public class EncryptionResponseBodyAdvice implements ResponseBodyAdvice<Object> {

    private final ObjectMapper objectMapper;

    public EncryptionResponseBodyAdvice(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }

    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType,
                                  Class<? extends HttpMessageConverter<?>> selectedConverterType,
                                  ServerHttpRequest request, ServerHttpResponse response) {
                                  
        if (body == null) return null;

        if (body instanceof EncryptedResponse) {
            return body;
        }

        if (request instanceof ServletServerHttpRequest servletRequest) {
            HttpServletRequest httpServletRequest = servletRequest.getServletRequest();
            HttpSession session = httpServletRequest.getSession(false);

            if (session != null && session.getAttribute("CLIENT_PUBLIC_KEY") != null) {
                try {
                    ClientKeyPairDTO clientKey = (ClientKeyPairDTO) session.getAttribute("CLIENT_PUBLIC_KEY");
                    RSAPublicKey rsaPublicKey = new RSAPublicKey(
                            clientKey.getE(),
                            new BigInteger(clientKey.getN())
                    );

                    String payload = objectMapper.writeValueAsString(body);
                    String encryptedPayload = RSAEncryption.encrypt(rsaPublicKey, payload);
                    String b64Payload = Base64.getEncoder().encodeToString(encryptedPayload.getBytes());

                    return new EncryptedResponse(b64Payload);

                } catch (Exception e) {
                    e.printStackTrace();
                    return body;
                }
            }
        }
        return body;
    }

    @Getter
    @AllArgsConstructor
    public static class EncryptedResponse {
        private String encryptedData;
    }
}
