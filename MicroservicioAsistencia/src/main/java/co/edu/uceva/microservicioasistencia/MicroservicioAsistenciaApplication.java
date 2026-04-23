package co.edu.uceva.microservicioasistencia;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class MicroservicioAsistenciaApplication {
    public static void main(String[] args) {
        SpringApplication.run(MicroservicioAsistenciaApplication.class, args);
    }
}
