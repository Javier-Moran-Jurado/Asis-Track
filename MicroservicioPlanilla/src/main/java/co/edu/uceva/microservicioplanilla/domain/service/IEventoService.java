package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;

import java.util.List;

public interface IEventoService {
    List<Evento> findAll();
    Evento findById(Long id);
    Evento save(Evento evento);
    Evento update(Evento evento);
    void deleteById(Long id);
    List<Evento> findByCodigoUsuario(Long codigoUsuario);
}
