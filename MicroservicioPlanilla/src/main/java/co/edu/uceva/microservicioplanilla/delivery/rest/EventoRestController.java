package co.edu.uceva.microservicioplanilla.delivery.rest;

import co.edu.uceva.microservicioplanilla.domain.model.Evento;
import co.edu.uceva.microservicioplanilla.domain.service.IEventoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/planilla-service/eventos")
@RequiredArgsConstructor
public class EventoRestController {

    private final IEventoService eventoService;

    @GetMapping
    public ResponseEntity<List<Evento>> findAll() {
        return ResponseEntity.ok(eventoService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Evento> findById(@PathVariable Long id) {
        return ResponseEntity.ok(eventoService.findById(id));
    }

    @GetMapping("/usuario/{codigoUsuario}")
    public ResponseEntity<List<Evento>> findByCodigoUsuario(@PathVariable Long codigoUsuario) {
        return ResponseEntity.ok(eventoService.findByCodigoUsuario(codigoUsuario));
    }

    @PostMapping
    public ResponseEntity<Evento> save(@RequestBody Evento evento) {
        return ResponseEntity.status(HttpStatus.CREATED).body(eventoService.save(evento));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Evento> update(@PathVariable Long id, @RequestBody Evento evento) {
        evento.setId(id);
        return ResponseEntity.ok(eventoService.update(evento));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteById(@PathVariable Long id) {
        eventoService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
