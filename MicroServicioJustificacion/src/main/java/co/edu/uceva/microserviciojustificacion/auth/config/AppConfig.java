package co.edu.uceva.microserviciojustificacion.auth.config;

import co.edu.uceva.microserviciojustificacion.domain.model.UsuarioSecure;
import co.edu.uceva.microserviciojustificacion.domain.repository.IUsuarioSecureRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class AppConfig {

    private final IUsuarioSecureRepository usuarioRepository;

    @Bean
    public UserDetailsService userDetailsService(){
        return username -> {
            Long codigo = Long.parseLong(username);
            final UsuarioSecure usuario = usuarioRepository.findById(codigo)
                    .orElseThrow(() -> new RuntimeException("Usuario no encontrado."));
            return org.springframework.security.core.userdetails.User.builder()
                    .username(codigo.toString())
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
    public AuthenticationManager authenticationManager(AuthenticationConfiguration cofig) throws Exception{
        return cofig.getAuthenticationManager();
    }
}
