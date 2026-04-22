package co.edu.uceva.microserviciousuario.auth.controller;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.io.Serializable;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ClientKeyPairDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long e;
    private String n;
    private String d;
}
