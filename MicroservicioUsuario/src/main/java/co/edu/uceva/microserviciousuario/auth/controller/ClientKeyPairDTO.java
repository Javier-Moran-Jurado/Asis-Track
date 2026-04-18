package co.edu.uceva.microserviciousuario.auth.controller;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ClientKeyPairDTO {
    private Long e;
    private String n;
    private String d;
}
