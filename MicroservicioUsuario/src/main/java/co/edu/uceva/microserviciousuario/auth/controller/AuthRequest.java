package co.edu.uceva.microserviciousuario.auth.controller;

public record AuthRequest(
        Long codigo,
        String password
) {
}