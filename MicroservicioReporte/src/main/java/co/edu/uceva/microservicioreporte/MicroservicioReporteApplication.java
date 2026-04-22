package co.edu.uceva.microservicioreporte;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class MicroservicioReporteApplication {

    public static void main(String[] args) {
        SpringApplication.run(MicroservicioReporteApplication.class, args);
    }
}