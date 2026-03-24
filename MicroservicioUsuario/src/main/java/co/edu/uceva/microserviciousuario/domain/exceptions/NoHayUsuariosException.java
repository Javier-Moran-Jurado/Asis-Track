package co.edu.uceva.microserviciousuario.domain.exceptions;

public class NoHayUsuariosException extends RuntimeException {
    public NoHayUsuariosException() {
        super("No hay usuarios en la base de datos.");
    }
}