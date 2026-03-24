package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Planilla;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface IPlanillaService {

    public List<Planilla> findAll();

    public Planilla findById(long id);

    public Planilla update(Planilla planilla);

    public Planilla save(Planilla planilla);

    public void deleteById(long id);

    public Page<Planilla> findAll(Pageable pageable);
}