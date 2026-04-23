package co.edu.uceva.microservicioreporte.auth.controller;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.io.Serializable;
@Getter @Setter @AllArgsConstructor @NoArgsConstructor
public class ClientKeyPairDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private String n;
    private long e;
}
