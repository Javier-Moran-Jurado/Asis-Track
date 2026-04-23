package co.edu.uceva.microserviciojustificacion;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class MicroServicioJustificacionApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroServicioJustificacionApplication.class, args);
    }

}
