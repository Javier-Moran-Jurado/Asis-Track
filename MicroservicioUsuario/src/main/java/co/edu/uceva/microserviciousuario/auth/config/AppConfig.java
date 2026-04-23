package co.edu.uceva.microserviciousuario.auth.config;

import co.edu.uceva.microserviciousuario.domain.exceptions.UsuarioNoEncontradoException;
import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import com.fasterxml.jackson.databind.DeserializationFeature;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.fasterxml.jackson.databind.ObjectMapper;


@Configuration
@RequiredArgsConstructor
public class AppConfig {

    private final IUsuarioRepository usuarioRepository;

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            Long codigo = Long.parseLong(username);
            final Usuario usuario = usuarioRepository.findById(codigo)
                    .orElseThrow(() -> new UsuarioNoEncontradoException(codigo));
            return org.springframework.security.core.userdetails.User.builder()
                    .username(codigo.toString())
                    .password(usuario.getContrasena())
                    .build();
        };
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return NoOpPasswordEncoder.getInstance();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration cofig) throws Exception {
        return cofig.getAuthenticationManager();
    }


    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return mapper;
    }
}
