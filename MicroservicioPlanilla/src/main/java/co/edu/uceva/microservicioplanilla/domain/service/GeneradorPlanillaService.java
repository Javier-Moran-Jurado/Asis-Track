package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.ConfirmarPropuestaRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.GenerarPropuestaRequest;
import co.edu.uceva.microservicioplanilla.delivery.rest.dto.PlanillaPropuestaResponse;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;

public interface GeneradorPlanillaService {
    PlanillaPropuestaResponse generarPropuesta(GenerarPropuestaRequest request);
    Planilla confirmarPropuesta(ConfirmarPropuestaRequest request);
}
