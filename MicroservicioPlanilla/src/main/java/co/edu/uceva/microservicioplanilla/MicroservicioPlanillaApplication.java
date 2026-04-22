package co.edu.uceva.microservicioplanilla;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class MicroservicioPlanillaApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroservicioPlanillaApplication.class, args);
    }

}
