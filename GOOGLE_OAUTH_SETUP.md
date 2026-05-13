# Configuración de Google OAuth2 para Asis-Track

Este documento describe los pasos necesarios para configurar y verificar el inicio de sesión con Google en la aplicación Asis-Track.

## Credenciales de Google Cloud Console

Las siguientes credenciales ya están integradas en el código. **No las compartas públicamente.**

| Plataforma | Client ID |
|------------|-----------|
| **Web** | `655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com` |
| **Android** | `655549064856-gqjhp91vaglqg2p8av8u6c0m7uhqvm2m.apps.googleusercontent.com` |

## Configuración del Backend (`MicroservicioUsuario`)

### Variable de entorno

El backend valida que el `audience` del token de Google coincida con los Client IDs permitidos. Esto se configura mediante la variable de entorno:

```bash
GOOGLE_CLIENT_IDS=655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com,655549064856-gqjhp91vaglqg2p8av8u6c0m7uhqvm2m.apps.googleusercontent.com
```

Si no se define la variable, el archivo `application.yml` ya contiene los valores por defecto.

### Flujo de validación del token

1. El backend recibe el `idToken` desde Flutter.
2. Verifica la firma digital contra los certificados públicos de Google (`https://www.googleapis.com/oauth2/v3/certs`).
3. Valida el emisor (`iss`): `https://accounts.google.com` o `accounts.google.com`.
4. Valida la audiencia (`aud`): debe coincidir con uno de los Client IDs configurados.
5. Verifica que el token no esté expirado (`exp`).
6. Extrae el correo electrónico (`email`) del payload.
7. Verifica que el correo termine en **`@uceva.edu.co`**.
   - Si no: responde `403 Forbidden` con el mensaje *"Solo se permite acceso con correo institucional (@uceva.edu.co)."*
8. Busca al usuario en la base de datos por su correo.
   - Si no existe: responde `403 Forbidden` con el mensaje *"Usuario no registrado. Contacte al administrador."*
   - Si existe: genera un `access_token` y `refresh_token` propios (JWT) y los retorna al cliente.

## Configuración del Frontend (Flutter)

### Dependencias

Las siguientes dependencias ya fueron agregadas a `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.2
  google_sign_in_web: ^0.12.4+3
```

Ejecuta en la terminal del proyecto Flutter:

```bash
flutter pub get
```

### Configuración Web (`web/index.html`)

El archivo `web/index.html` ya incluye el script de Google Identity Services y el `meta` tag con el Client ID de Web:

```html
<script src="https://accounts.google.com/gsi/client" async defer></script>
<meta name="google-signin-client_id" content="655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com">
```

### Configuración Android

Para que `google_sign_in` funcione correctamente en Android, debes agregar el archivo `google-services.json` si usas Firebase, o configurar manualmente el SHA-1 de tu certificado de firma en Google Cloud Console.

#### Obtener el SHA-1 (Debug)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Luego, ve a [Google Cloud Console > APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials), edita el Client ID de Android y agrega el SHA-1 fingerprint.

#### Si usas Firebase (opcional pero recomendado)

1. Ve a [Firebase Console](https://console.firebase.google.com/).
2. Crea/importa tu proyecto.
3. Agrega una app Android con el `package name` de tu aplicación.
4. Descarga `google-services.json` y colócalo en:
   ```
   android/app/google-services.json
   ```
5. Aplica el plugin de Firebase en `android/app/build.gradle`.

### Configuración iOS

Para iOS, asegúrate de que el `Bundle Identifier` en tu proyecto Xcode coincida con el configurado en Google Cloud Console para el Client ID de iOS (si llegas a crear uno).

## Verificación del flujo completo

### Escenarios de prueba

| Escenario | Resultado esperado |
|-----------|-------------------|
| Usuario con correo `@uceva.edu.co` registrado en BD | Éxito: emite JWT y navega al home |
| Usuario con correo `@uceve.edu.co` **no** registrado en BD | Error: *"Usuario no registrado. Contacte al administrador."* |
| Usuario con correo `@gmail.com` | Error: *"Solo se permite acceso con correo institucional (@uceva.edu.co)."* |
| Login manual (código/contraseña) | Funciona igual que antes (sin regresiones) |
| Cancelar picker de Google | No muestra error, permanece en login |

### Endpoints del backend

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/v1/auth/login` | Login manual (existente) |
| `POST` | `/api/v1/auth/oauth2/google` | Login con Google (nuevo) |
| `POST` | `/api/v1/auth/refresh` | Refrescar token (existente) |

## Solución de problemas comunes

### Error: `Token de Google invalido o expirado`

- Verifica que el `idToken` se esté enviando correctamente desde Flutter.
- Asegúrate de que el reloj del servidor esté sincronizado (NTP).
- Revisa que los Client IDs en `application.yml` sean correctos y no tengan espacios.

### Error: ` audience` no coincide

- Si estás probando en Web, el `aud` del token será el Client ID de Web.
- Si estás probando en Android, el `aud` será el Client ID de Android.
- Asegúrate de que ambos Client IDs estén en la lista `GOOGLE_CLIENT_IDS`.

### Error en Flutter Web: `Not a valid origin for the client`

- Ve a Google Cloud Console > Credentials > tu Client ID de Web.
- En **Authorized JavaScript origins**, agrega los orígenes desde donde sirves la app:
  - `http://localhost:8080`
  - `http://localhost:5000`
  - `https://tudominio.com`

### Error en Flutter Android: `PlatformException(sign_in_failed, ...)`

- Verifica que el SHA-1 de tu certificado esté registrado en Google Cloud Console.
- Asegúrate de que el `applicationId` en `android/app/build.gradle` coincida con el configurado en Google Cloud Console.

## Notas de seguridad

1. **Nunca subas `google-services.json` ni credenciales a repositorios públicos.** Asegúrate de que estos archivos estén en `.gitignore`.
2. El backend **siempre** valida el dominio `@uceva.edu.co`. No confíes en que el frontend filtre esto.
3. Los tokens de Google (`idToken`) son de corta duración (~1 hora). El backend emite sus propios JWTs con la duración configurada en `application.yml`.
4. El `client_secret` no se usa en el flujo de OAuth2 para móvil/Web (PKCE / Implicit). Solo se usa si implementas un flujo de servidor a servidor.

## Contacto

Si encuentras problemas durante la configuración, revisa los logs del backend (`MicroservicioUsuario`) y la consola de Flutter para mensajes de error detallados.
