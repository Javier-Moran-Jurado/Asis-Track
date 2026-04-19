package co.edu.uceva.microserviciousuario.auth.controller;

import lombok.Getter;
import lombok.Setter;
import java.io.Serializable;

@Getter
@Setter
public class ClientKeyPairDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long e;
    private String n;
    private String d;
}
