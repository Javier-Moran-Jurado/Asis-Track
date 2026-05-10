package co.edu.uceva.microserviciousuario.auth.service;

import co.edu.uceva.microserviciousuario.auth.controller.AuthRequest;
import co.edu.uceva.microserviciousuario.auth.controller.LoginRequest;
import co.edu.uceva.microserviciousuario.auth.controller.TokenResponse;

import co.edu.uceva.microserviciousuario.domain.exceptions.UsuarioNoEncontradoException;
import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.repository.IUsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final IUsuarioRepository usuarioRepository;

    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public TokenResponse login(LoginRequest request){
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.codigo(),
                        request.contrasena()
                )
        );
        Usuario usuario = usuarioRepository.findByCodigo(request.codigo())
                .orElseThrow(() -> new UsuarioNoEncontradoException(request.codigo()));
        String jwtToken = jwtService.generateToken(usuario);
        String jwtRefreshToken = jwtService.generateRefreshToken(usuario);
        return new TokenResponse(jwtToken, jwtRefreshToken);
    }

    public TokenResponse refreshToken(final String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("Invalid Bearer token");
        }

        final String refreshToken = authHeader.substring(7);
        final Long usuarioCodigo = jwtService.extractCodigo(refreshToken);

        if (usuarioCodigo == null) {
            throw new IllegalArgumentException("Invalid Refresh Token");
        }
        final Usuario usuario = usuarioRepository.findByCodigo(usuarioCodigo).orElseThrow(() -> new UsuarioNoEncontradoException(usuarioCodigo));
        final boolean isTokenValid = jwtService.isTokenValid(refreshToken, usuario);
        if (!isTokenValid) {
            return null;
        }

        final String accessToken = jwtService.generateRefreshToken(usuario);

        return new TokenResponse(accessToken, refreshToken);
    }

    public TokenResponse authenticate(final AuthRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.codigo(),
                        request.password()
                )
        );
        final Usuario usuario = usuarioRepository.findByCodigo(request.codigo())
                .orElseThrow();
        final String accessToken = jwtService.generateToken(usuario);
        final String refreshToken = jwtService.generateRefreshToken(usuario);
        return new TokenResponse(accessToken, refreshToken);
    }
}
