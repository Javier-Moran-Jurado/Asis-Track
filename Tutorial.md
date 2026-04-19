# 🛡️ Tutorial Completo: Arquitectura Criptográfica y Sesiones

Este documento funciona como una **guía integral** para entender todo el ecosistema de seguridad en reposo (At-Rest) y en tránsito (E2E) que hemos construido entre el `MicroServicioSeguridad` y el `MicroservicioUsuario`. Además, te enseñará cómo simular un cliente Frontend usando **Postman** u otra herramienta API REST para ver la magia en funcionamiento.

---

## 🏗️ Resumen de la Arquitectura Implementada

### 1. Sistema Nervioso Central (MicroServicioSeguridad)
Es el único responsable de generar pares de llaves RSA. Expone:
- `GET /public` para que cualquiera pueda encriptar datos para el Backend.
- `GET /private` (Protegido por `X-Internal-Secret`) para que los microservicios desencripten los payloads históricos y validen la seguridad.

### 2. Cifrado en Base de Datos In-House (`UsuarioConverter`)
En vez de guardar correos y contraseñas y otros datos expuestos, el `MicroservicioUsuario` intercepta matemáticamente las consultas a PostgreSQL:
- **Al  Guardar (`INSERT/UPDATE`)**: Obtiene de su **Caché** la pública del *Seguridad*. Cifra usando `RSAEncryption`, lo convierte a Base64 y añade el prefijo de qué llave usó (`ID:TEXTO_B64`).
- **Al Leer (`SELECT`)**: Obtiene el ID, pide al MS_Seguridad su respectiva Privada Histórica, descifra de Base64, e invierte la ecuación matemática entregándole texto plano normal a Spring Data JPA. Todo en milisegundos gracias a **Redis Caché**.

### 3. Cifrado de Extremo a Extremo en las APIs (`EncryptionResponseBodyAdvice`)
Para evitar que datos salgan desnudos hacia la red, el Backend le pide al cliente que dicte cómo debe hablarle:
- Guarda la Llave generada del Cliente localmente en **Sesiones de Redis**.
- Cuando un Controller (EJ. Listar usuarios) emite una respuesta, nuestro filtro "secuestra" el JSON de salida, la reempaqueta como String con la llave del cliente y devuelve exclusivamente: `{"encryptedData" : "..."}`.

---

## 🚀 Guía de Pruebas SIN Frontend (Postman / Insomnia)

Dado que un "Frontend Vivo" no existe todavía, vamos a emular el comportamiento de sus librerías a mano.

### Prerrequisitos de Ejecución
1. Arranca una base de datos PostgreSQL estándar (asegúrate de que ambos microservicios se puedan conectar).
2. Arranca una instancia de **Redis** (`docker run -d -p 6379:6379 redis`).
3. Inicia el `MicroServicioSeguridad` (correrá típicamente en `8085`).
4. Inicia el `MicroservicioUsuario` (asegúrate de que su `.yml` apunte a Redis y al puerto `8085`).

### 🧪 Prueba 1: Validando la de Base de Datos Encriptada (At-Rest)
Vamos a verificar que el Converter está operando limpiamente sin alterar ni molestar a los Controladores JPA tradicionales.

1. **Abre Postman**, haz un `POST` para crear un nuevo `Usuario` hacia el endpoint CRUD que tengas.
2. Abre **pgAdmin** o un shell de Base de Datos.
3. Chequea tu tabla `usuario`:
   - Deberás ver que la columna `nombre_completo` o `contrasena` _NO_ tiene el nombre real allí escrito, sino que es una cadena inentendible con el formato `<ID>:NDg1OTg0Z...` (ej: `1:Ykc4cGJhRjF...`).
4. **Validación Inversa**: Vuelve a Postman y haz un `GET` pidiendo a ese mismo usuario o todos los usuarios.
   - Vas a notar que el JSON te devuelve los datos de correo y nombre *TOTALMENTE EN TEXTO CLARO*. Magia Pura (JPA + Redis Cache).

### 🧪 Prueba 2: Simulando el Intercambio E2E de Llave (Frontend-Backend)
El Frontend enviaría su propia llave encriptada. Vamos a fabricar lo que manda el front.

1. Como "Frontend", debemos tener un par matemático e,n y d. Asumiremos los tuyos: `e=65537`, `n=323490283...` etc.
2. Como simulamos el Frontend en Postman, no tenemos la fórmula nativa para encriptar en RSA Java. Simplemente vamos a crear por un momento una petición cruda a un script que nos de un número pre-encriptado (puedes usar un minúsculo código Main `RSAEncryption.encrypt()` en tu propio IDE inyectando los datos de la llave Pública obtenida de `http://localhost:8085/api/v1/security/keys/public`). Ese código te debe arrojar una encriptación al formato de String Java tu JSON: 
   ```json
   {"e":65537, "n":"190283908...", "d":"1892839"}
   ```
3. Guarda el output gigante (vamos a llamarlo `ENCRYPTED_TEXT_FROM_IDE_FRONTEND`).

### 🧪 Prueba 3: Registrando tu Sesión en Redis

1. Abre **Postman**.
2. Efectúa una llamada **`POST`** a la URL: `http://localhost:8080/api/v1/auth/session-key`.
3. Pega en el body tipo *Raw (JSON)* el texto que encriptaste simuladamente en la prueba 2:
   ```json
   {
      "encryptedPayload": "ENCRYPTED_TEXT_FROM_IDE_FRONTEND"
   }
   ```
4. **IMPORTANTE:** Cuando aprietes "Send", el servidor descifrará tu payload y lo guardará en Redis. Fíjate en la pestaña `Cookies` de la respuesta de Postman. Postman guardará automáticamente un Token que luce tipo: `SESSION=MzkxYThhM...`.

### 🧪 Prueba 4: Navegando como Usuario E2E

Ya que la Cookie `SESSION` se guardó en Postman de la llamada anterior:

1. Ingresa ahora al Endpoint que expone todos los usuarios (`GET /api/v1/usuarios` - o cualquier ruta válida).
2. Dispara la petición (Postman enviará tu Cookie de modo que el Backend entenderá que sigues siendo tú interactuado).
3. **El Comportamiento Triunfante**: 
   A diferencia de la *Prueba 1* (donde veías listas normales de JSON plano), verás en rojo u oscuro que el servidor de Spring no te arrojó el Array de Usuarios común y corriente. Te devolverá en su lugar:
   ```json
   {
       "encryptedData": "NGZnc2Rmc2RmczM0cjQ... base64 del modelo serializado y encriptado con TU llave front ..."
   }
   ```
   **¡Felicidades!** Estás contemplando la interceptación en tiempo real. Nadie que intercepte la red HTTP verá los nombres o correos de la DB, porque están fuertemente cifrados con la llave del cliente antes de salir a volar al exterior.
