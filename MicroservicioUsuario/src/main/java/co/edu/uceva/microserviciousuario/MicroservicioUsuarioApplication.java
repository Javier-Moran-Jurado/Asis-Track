package co.edu.uceva.microserviciousuario;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class MicroservicioUsuarioApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroservicioUsuarioApplication.class, args);
    }

}
