# Microservicio de Usuario (User Management)

Este microservicio se encarga del núcleo de la autenticación local (JWT), la persistencia e inicio de sesión de usuarios, y funge como un middleware clave para manejar arquitecturas State-less transitorias y encriptación E2E hacia el frontend apoyándose en bases de datos Redis, Spring Security y nuestro módulo criptográfico personalizado local `Encryption`.

---

## 🏛 Arquitectura de Capas Existente

- **Auth & JWT (`SecurityConfig`, `JwtService`)**: Maneja el ciclo de vida, la expiración de tokens (1 día o 1 semana para refresh) validando contra la Secret Key, protegiendo todos los endpoints salvo `GET` y Auth genéricos.
- **Delivery (`RestController`)**: Expone a la red los puntos de entrada para la gestión CRUD sobre las entidades (Usuarios, Profesores).
- **Domain (`Service` y `Entities`)**: Lógica operacional conectada al estándar de Spring Data JPA corriendo bajo una base de datos PostgreSQL remota y protegida.

---

## 🔒 Novedad: Cifrado de Extremo a Extremo (E2E) con Redis

Recientemente, el microservicio se potenció integrándose al ecosistema central del *MicroServicioSeguridad*. Ahora somos capaces de habilitar una conexión cifrada en crudo (`co.uceva.edu.Encryption.RSAEncryption`) respondiéndole al cliente exclusivamente a través de **sus llaves originadas en Frontend**.

### Flujo Completo Implementado:

1. **El Frontend genera su par RSA**. El cliente envuelve un JSON (`e, n, d` - equivalente estructural a un `ClientKeyPairDTO`) cifrado de punta con la *Llave Pública* actual del *MicroServicioSeguridad*.
2. El cliente hace un `POST` nuestro a [`/api/v1/auth/session-key`](./src/main/java/co/edu/uceva/microserviciousuario/auth/controller/AuthController.java#L27).
3. **Peticion M2M.** Nuestro MicroservicioUsuario realiza una petición HTTP al *MicroServicioSeguridad* [`GET /api/v1/security/keys/private`](./src/main/java/co/edu/uceva/microserviciousuario/domain/service/SecurityIntegrationService.java#L27) mediante un `RestTemplate` utilizando el _Header_ de interconexión M2M (`X-Internal-Secret`).
4. **Desencriptación**. Al recibir la Llave Privada central, desencriptamos matemáticamente el payload mandado por el cliente, extrayendo exitosamente los valores originales `e`, `n` y `d`.
5. **Caché en Redis**. Se habilitó [`@EnableRedisHttpSession`](./src/main/java/co/edu/uceva/microserviciousuario/auth/config/RedisSessionConfig.java) y configuramos el repositorio y las sesiones para viajar automáticamente hacia Redis y expirar transparentemente (`HttpSession`). Este objeto con `e` y `n` se persiste en memoria caché compartida.
6. **Encripción por Hardware Automática (`ResponseBodyAdvice`)**. Finalmente, cualquier respuesta futura de los RestControllers (como un Endpoint para listar Usuarios de forma segura), es atajada por defecto antes de ser inyectada al flujo web. Nuestro interceptor inteligente, [`EncryptionResponseBodyAdvice`](./src/main/java/co/edu/uceva/microserviciousuario/auth/config/EncryptionResponseBodyAdvice.java#L22):
    - Verifica si existe la llave del cliente en *Session*.
    - Serializa todos los modelos (Usuario) y lo encripta en crudo con la pública del cliente (`RSAEncryption.encrypt(clientPublicKey) ...`).
    - Modifica la red devolviendo un `JSON` especial con puras variables y números incoherentes en formato `{ "encryptedData" : "xxx" }`, asegurando que viajen de manera que solo el Frontend logre abrirlos.

### Anotaciones Críticas

- `@EnableRedisHttpSession`: Se usa dentro de las clases `@Configuration` para sobreescribir el comportamiento clásico de Tomcat Sessions, serializando todo mediante beans de red hacia el servidor en caché y devolviendo la Cookie de Sesión segura.
- `@ControllerAdvice` + `ResponseBodyAdvice`: Permite "cortar horizontalmente" (*Cross-cutting Concern* del patrón AOP) todas las respuestas de todos los Controladores antes de invocar la transformación con `Jackson` (`MappingJackson2HttpMessageConverter`), permitiendo un formato puro encubierto sin intervenir intrusivamente con código base repetitivo todos y cada uno de los métodos de servicio.
