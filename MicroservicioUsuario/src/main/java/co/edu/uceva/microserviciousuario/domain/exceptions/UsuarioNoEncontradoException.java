package co.edu.uceva.microserviciousuario.domain.exceptions;

public class UsuarioNoEncontradoException extends RuntimeException {
    public UsuarioNoEncontradoException(Long codigo) {
        super("El usuario con Codigo " + codigo + " no fue encontrado.");
    }
}