# MicroServicio de Seguridad (Keys Management)

Este microservicio se ha diseñado como una solución centralizada y robusta para la gestión, distribución, almacenamiento y rotación periódica de pares de llaves RSA en una arquitectura de microservicios.

## Implementaciones Principales

1. **Dependencia Criptográfica Nativa (`Encryption`)**: 
   El servicio utiliza el paquete local de la universidad/proyecto [`co.uceva.edu.Encryption`](../Encryption/pom.xml). Se encargó de hacer la suplantación de implementaciones estandarizadas complejas, y se utiliza para generar los pares matemáticos (p, q, n, d, e) así como para cifrar y descifrar la llave privada **antes de tocar la base de datos**.
2. **[Scheduled Tasks](./src/main/java/co/edu/uceva/microservicioseguridad/domain/service/SecurityKeyServiceImpl.java#L39) (Rotación Automática)**:
   Se ha puesto en marcha un servicio programado (`@Scheduled`) dependiente del delay establecido en `app.security.rotation-delay`. Por defecto, genera, invalida y activa un nuevo par de llaves cada semana para mitigar riesgos de filtraciones de datos por mucho tiempo.

---

## Medidas de Seguridad

Este microservicio emplea una defensa multinivel (*Defense in Depth*):

- **Cifrado At-Rest (En reposo):** 
  En ningún momento la llave privada RSA es guardada en texto plano (`d`). Se configura en variables de entorno o *Config Server* una [«Master Key RSA» maestra](./src/main/resources/application.yml#L20-L24) (`MASTER_KEY_E`, `MASTER_KEY_N`, `MASTER_KEY_D`). Se usa esta Master para encriptar criptográficamente la llave operativa en la Base de Datos.
- **Autenticación Máquina a Máquina (M2M):** 
  Los endpoints marcados como `/private` obligan que entre los *headers* de la petición HTTTP viaje explícitamente `X-Internal-Secret`, cuyo valor debe coincidir con la configuración desplegada, asegurando que solo el tráfico interno del clúster puede obtener el descifrado.
- **Autenticación JWT Sin Estado (Stateless):**
  Despojado de su conexión a Base de Datos local mediante el `ITokenRepository`, este microservicio procesa y descifra los tokens enviados interceptando las peticiones a través del [`JwtAuthFilter`](./src/main/java/co/edu/uceva/microservicioseguridad/auth/config/JwtAuthFilter.java). Valida firmas mediante HMAC-SHA delegando su validación sin requerir una consulta asíncrona a credenciales.
- **Restricción por Roles:**
  Endpoints críticos como la _fuerza de rotación de llaves_ evalúan semánticamente el perfil extraido del JWT para accionar el código si, y solamente si, el emisor posee permisos avanzados.

---

## Endpoints

### 1. [`GET /api/v1/security/keys/public`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L24)
- **Acceso:** Público general (*Cualquiera*).
- **Descripción:** Distribuye la llave pública activa actual (retorna `id`, `publicN` y `publicE`).

### 2. [`GET /api/v1/security/keys/private`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L30)
- **Acceso:** Restringido a tráfico interno (`X-Internal-Secret`).
- **Descripción:** Distribuye la llave privada activa actual de manera desencriptada a otros microservicios que necesiten procesar la información sensible (retorna `id`, `privateD` y `publicN`).

### 3. [`GET /api/v1/security/keys/private/{id}`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L47)
- **Acceso:** Restringido a tráfico interno (`X-Internal-Secret`).
- **Descripción:** Permite a los demás servicios consultar y reconstruir el objeto llaves exacto que se usó históricamente para cifrar un dato (usando su `id`).

### 4. [`POST /api/v1/security/keys/rotate`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L39)
- **Acceso:** Máximo Nivel (JWT válido + Rol `Administrador`).
- **Descripción:** Endopoint manual para invalidar las llaves activas y forzar inmediatamente la generación de un par nuevo (en caso de emergencia o filtración humana). 

---

## Anotaciones Utilizadas Explicadas

- [`@Scheduled(fixedDelayString = ...)`](./src/main/java/co/edu/uceva/microservicioseguridad/domain/service/SecurityKeyServiceImpl.java#L39): Marca un método para ser introducido en un pool de threads en background para ejecutarse infinitamente al ritmo indicado por *cron* o en intervalos de milisegundos.
- [`@PreAuthorize("hasRole('Administrador')")`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L40): Anotación provista por [`@EnableMethodSecurity`](./src/main/java/co/edu/uceva/microservicioseguridad/auth/config/SecurityConfig.java#L16). Funciona procesando un "point-cut" en AOP. Captura el llamado a tiempo de ejecución, lee el *SecurityContextHolder* del hilo que procesa el request, observa la lista de *Authorities*, y si no matchea, lanza una intercepción `403 Forbidden` bloqueando de origen al controlador.
- [`@Value("${...}")`](./src/main/java/co/edu/uceva/microservicioseguridad/domain/service/SecurityKeyServiceImpl.java#L27): Permite inyectar de manera reactiva o constante elementos del archivo de propiedades externo (`application.yml`) como la clave maestra o el secreto JWT.
- [`@RestController` y `@RequestMapping`](./src/main/java/co/edu/uceva/microservicioseguridad/delivery/rest/SecurityKeyController.java#L13): Definen el comportamiento estándar de exposición y serialización de JSON bajo Spring Web, además de un prefijo de URI global para encapsular la capa.
- [`@PostConstruct`](./src/main/java/co/edu/uceva/microservicioseguridad/domain/service/SecurityKeyServiceImpl.java#L100): Le indica a Spring que tan pronto instancíe por primera vez el componente, e inyecte los repositorios, corra un método específico (como crear la primera llave por defecto de la base de datos vacía al iniciar la aplicación).
