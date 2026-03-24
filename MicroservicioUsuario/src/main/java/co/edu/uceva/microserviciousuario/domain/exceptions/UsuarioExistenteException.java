package co.edu.uceva.microserviciousuario.domain.exceptions;

public class UsuarioExistenteException extends RuntimeException {
    public UsuarioExistenteException(long codigo) {
        super("El usuario con codigo '" + codigo + "' ya existe.");
    }
}