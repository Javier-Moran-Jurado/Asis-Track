package co.edu.uceva.microserviciousuario.domain.exceptions;

public class PaginaSinUsuariosException extends RuntimeException{
    public PaginaSinUsuariosException(int page) {
        super("No hay usuarios en la página solicitada: " + page);
    }
}
