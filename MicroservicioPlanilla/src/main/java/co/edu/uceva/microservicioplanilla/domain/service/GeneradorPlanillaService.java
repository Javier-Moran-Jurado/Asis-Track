package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.PlanillaResponse;

public interface GeneradorPlanillaService {
    PlanillaResponse generarYGuardarPropuesta(String descripcion, Long lugarId, Long eventoId);
}
