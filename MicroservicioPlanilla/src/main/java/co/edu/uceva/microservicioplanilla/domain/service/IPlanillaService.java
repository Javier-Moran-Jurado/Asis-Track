package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.delivery.rest.dto.PlanillaRequest;
import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface IPlanillaService {

    List<Planilla> findAll();

    Planilla findById(long id);

    Planilla update(Long id, PlanillaRequest request);

    Planilla save(PlanillaRequest request);

    void deleteById(long id);

    Page<Planilla> findAll(Pageable pageable);
}
