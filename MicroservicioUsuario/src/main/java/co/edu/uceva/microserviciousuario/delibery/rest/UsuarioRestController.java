package co.edu.uceva.microserviciousuario.delibery.rest;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import co.edu.uceva.microserviciousuario.domain.exceptions.NoHayUsuariosException;
import co.edu.uceva.microserviciousuario.domain.exceptions.PaginaSinUsuariosException;
import co.edu.uceva.microserviciousuario.domain.exceptions.UsuarioExistenteException;
import co.edu.uceva.microserviciousuario.domain.exceptions.UsuarioNoEncontradoException;
import co.edu.uceva.microserviciousuario.domain.exceptions.ValidationException;
import co.edu.uceva.microserviciousuario.domain.model.Usuario;
import co.edu.uceva.microserviciousuario.domain.service.IUsuarioService;
import jakarta.validation.Valid;

@RestController
@CrossOrigin
@RequestMapping("/api/v1/usuario-service")
public class UsuarioRestController {
    private final IUsuarioService usuarioService;

    private static final String MENSAJE = "mensaje";
    private static final String USUARIO = "usuario";
    private static final String USUARIOS = "usuarios";

    public UsuarioRestController(IUsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @GetMapping("/usuarios")
    @PreAuthorize("isAuthenticated() and !hasAnyRole('Estudiante', 'Monitor')")
    public ResponseEntity<Map<String, Object>> getUsuarios() {
        Map<String, Object> response = new HashMap<>();
        List<Usuario> usuarios = usuarioService.findAll();
        if (usuarios.isEmpty()) {
            throw new NoHayUsuariosException();
        }
        response.put(USUARIOS, usuarios);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/usuario/page/{page}")
    @PreAuthorize("isAuthenticated() and !hasAnyRole('Estudiante', 'Monitor')")
    public ResponseEntity<Object> index(@PathVariable Integer page) {
        Pageable pageable = PageRequest.of(page, 4);
        Page<Usuario> usuarios = usuarioService.findAll(pageable);
        if (usuarios.isEmpty()) {
            throw new PaginaSinUsuariosException(page);
        }
        return ResponseEntity.ok(usuarios);
    }

    @PostMapping("/usuarios")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    public ResponseEntity<Map<String, Object>> save(@Valid @RequestBody Usuario usuario, BindingResult bindingResult) {
        Map<String, Object> response = new HashMap<>();
        if (bindingResult.hasErrors()) {
            throw new ValidationException(bindingResult);
        }
        if(usuario.getCodigo() != null &&
                usuarioService.findById(usuario.getCodigo()).orElse(null) != null) {
            throw new UsuarioExistenteException(usuario.getCodigo());
        }
        Usuario nuevoUsuario = usuarioService.save(usuario);
        response.put(MENSAJE, "El usuario ha sido creado con éxito!");
        response.put(USUARIO, nuevoUsuario);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping("/usuarios")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    public ResponseEntity<Map<String, Object>> delete(@RequestBody Usuario usuario) {
        Map<String, Object> response = new HashMap<>();
        usuarioService.findById(usuario.getCodigo()).orElseThrow(
                () -> new UsuarioNoEncontradoException(usuario.getCodigo())
        );
        usuarioService.delete(usuario);
        response.put(MENSAJE, "El usuario ha sido eliminado con éxito!");
        response.put(USUARIO, null);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/usuarios")
    @PreAuthorize("isAuthenticated() and hasAnyRole('Administrador', 'Administrativo')")
    public ResponseEntity<Map<String, Object>> update(@Valid @RequestBody Usuario usuario, BindingResult bindingResult) {
        Map<String, Object> response = new HashMap<>();
        if (bindingResult.hasErrors()) {
            throw new ValidationException(bindingResult);
        }
        usuarioService.findById(usuario.getCodigo()).orElseThrow(
                () -> new UsuarioNoEncontradoException(usuario.getCodigo())
        );
        Usuario usuarioActualizado = usuarioService.update(usuario);
        response.put(MENSAJE, "El usuario ha sido actualizado con éxito!");
        response.put(USUARIO, usuarioActualizado);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/usuarios/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> findById(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();
        Usuario usuario = usuarioService.findById(id).orElseThrow(
                () -> new UsuarioNoEncontradoException(id)
        );
        response.put(MENSAJE, "El usuario ha sido encontrado!");
        response.put(USUARIO, usuario);
        return ResponseEntity.ok(response);
    }
}