package co.edu.uceva.microserviciousuario.delibery.rest;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.service.IUsuarioService;

@RestController
@RequestMapping("/api/v1/usuario-service")
public class UsuarioRestController {
    private final IUsuarioService usuarioService;

    public UsuarioRestController(IUsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @GetMapping("/usuarios")
    public List<Usuario> getUsuarios() {
        return usuarioService.findAll();
    }

    @GetMapping("/usuarios/page/{page}")
    public Page<Usuario> index(@PathVariable Integer page) {
        Pageable pageable = PageRequest.of(page, 4);
        return usuarioService.findAll(pageable);
    }

    @PostMapping("/usuarios")
    public Usuario save(@RequestBody Usuario usuario) {
        return usuarioService.save(usuario);
    }

    @DeleteMapping("/usuarios")
    public void delete(@RequestBody Usuario usuario) {
        usuarioService.delete(usuario);
    }

    @PutMapping("/usuarios")
    public Usuario update(@RequestBody Usuario usuario) {
        return usuarioService.update(usuario);
    }

    @GetMapping("/usuarios/{id}")
    public Usuario findById(@PathVariable Long id) {
        return usuarioService.findById(id);
    }
}