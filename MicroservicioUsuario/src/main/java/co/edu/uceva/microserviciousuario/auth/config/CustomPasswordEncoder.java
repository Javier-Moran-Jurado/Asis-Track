package co.edu.uceva.microserviciousuario.auth.config;

import org.springframework.security.crypto.password.AbstractValidatingPasswordEncoder;

public class CustomPasswordEncoder extends AbstractValidatingPasswordEncoder {
    @Override
    protected String encodeNonNullPassword(String rawPassword) {
        return "";
    }

    @Override
    protected boolean matchesNonNull(String rawPassword, String encodedPassword) {
        return false;
    }
}
