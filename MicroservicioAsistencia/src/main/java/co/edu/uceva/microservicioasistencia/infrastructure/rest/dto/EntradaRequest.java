package co.edu.uceva.microservicioasistencia.infrastructure.rest.dto;

import lombok.Data;

@Data
public class EntradaRequest {
    private Geolocalizacion geolocalizacion;
    private DatosAdicionales datosAdicionales;

    @Data
    public static class Geolocalizacion {
        private double lat;
        private double lng;
        private Integer precision;
    }

    @Data
    public static class DatosAdicionales {
        private String dispositivo;
        private String appVersion;
        private Integer bateria;
        private String red;
        private String sistema;
    }
}