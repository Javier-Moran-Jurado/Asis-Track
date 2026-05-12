package co.edu.uceva.microservicioplanilla.auth.controller;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SessionKeyRequest {
    private String encryptedPayload;
}
