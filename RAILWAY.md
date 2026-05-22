# Despliegue en Railway

Este proyecto está preparado para desplegarse en [Railway](https://railway.app) como múltiples servicios independientes.

## Servicios Requeridos

| Servicio | Imagen / Build | Tipo de Servicio | Exposición |
|---|---|---|---|
| `nginx-gateway` | `nginx-gateway/Dockerfile` | Web | Pública (único punto de entrada) |
| `usuarioservice` | `MicroservicioUsuario/Dockerfile` | Private | Privada (solo via nginx-gateway) |
| `planilla-service` | `MicroservicioPlanilla/Dockerfile` | Private | Privada (solo via nginx-gateway) |
| `seguridad-service` | `MicroServicioSeguridad/Dockerfile` | Private | Privada (solo `/public` via nginx-gateway) |
| `db-usuario` | `postgres:alpine` | Database | Privada |
| `db-planilla` | `postgres:alpine` | Database | Privada |
| `db-seguridad` | `postgres:alpine` | Database | Privada |
| `redis` | `redis:alpine` | Private | Privada |

> **Nota:** En Railway, las bases de datos PostgreSQL y Redis pueden crearse como servicios nativos de Railway (más fácil) o como contenedores Docker.

---

## Variables de Entorno por Servicio

### `nginx-gateway`

| Variable | Descripción | Ejemplo Railway |
|---|---|---|
| `NGINX_PORT` | Railway inyecta `$PORT`; mapea a este valor | `${PORT}` |
| `UPSTREAM_USUARIO` | Host interno del `usuarioservice` | `usuarioservice.railway.internal:8080` |
| `UPSTREAM_PLANILLA` | Host interno del `planilla-service` | `planilla-service.railway.internal:8080` |
| `UPSTREAM_SEGURIDAD` | Host interno del `seguridad-service` | `seguridad-service.railway.internal:8085` |

> Railway Private Networking usa el formato `<servicio>.railway.internal`. No es necesario incluir el puerto si Railway lo maneja, pero para servicios custom se recomienda `:8080`, `:8085`, etc.

### `usuarioservice`

| Variable | Descripción | Ejemplo |
|---|---|---|
| `PORT` | Puerto interno del servicio | `8080` |
| `SECRET_KEY` | Clave secreta para JWT | `super-secret-key` |
| `DB_USER` | Usuario PostgreSQL | `postgres` |
| `DB_PASS` | Contraseña PostgreSQL | `password` |
| `DB_HOST` | JDBC URL de la DB | `jdbc:postgresql://db-usuario.railway.internal:5432/asis_track_db` |
| `JPA_DDL` | Estrategia Hibernate | `update` o `validate` |
| `REDIS_HOST` | Host de Redis | `redis.railway.internal` |
| `REDIS_PORT` | Puerto de Redis | `6379` |
| `SECURITY_URL` | URL interna del servicio de seguridad | `http://seguridad-service.railway.internal:8085` |
| `INTERNAL_SECRET` | Secreto compartido entre microservicios | `microservice-internal-secret` |
| `GOOGLE_CLIENT_IDS` | IDs de clientes OAuth2 de Google | `id1,id2` |

### `planilla-service`

| Variable | Descripción | Ejemplo |
|---|---|---|
| `PORT` | Puerto interno | `8080` |
| `SECRET_KEY` | Clave secreta para JWT | `super-secret-key` |
| `DB_USER` | Usuario PostgreSQL | `postgres` |
| `DB_PASS` | Contraseña PostgreSQL | `password` |
| `DB_HOST` | JDBC URL | `jdbc:postgresql://db-planilla.railway.internal:5432/asis_track_db` |
| `DB_NAME` | Nombre de la base de datos | `asis_track_db` |
| `JPA_DDL` | Estrategia Hibernate | `update` |
| `REDIS_HOST` | Host de Redis | `redis.railway.internal` |
| `REDIS_PORT` | Puerto de Redis | `6379` |
| `SECURITY_URL` | URL interna del servicio de seguridad | `http://seguridad-service.railway.internal:8085` |
| `INTERNAL_SECRET` | Secreto compartido entre microservicios | `microservice-internal-secret` |
| `AI_PRIMARY_PROVIDER` | Proveedor AI principal | `groq` |
| `AI_CLOUD_MODEL` | Modelo en la nube | `gpt-4o-mini` |
| `OPENAI_BASE_URL` | Base URL OpenAI | `https://api.openai.com` |
| `OPENAI_API_KEY` | API Key OpenAI | `sk-...` |
| `HF_URL` | URL HuggingFace | `https://router.huggingface.co/...` |
| `HF_TOKEN` | Token HuggingFace | `hf_...` |
| `GROQ_URL` | URL Groq | `https://api.groq.com/openai/v1` |
| `GROQ_TOKEN` | Token Groq | `gsk_...` |
| `GROQ_MODEL` | Modelo Groq | `meta-llama/llama-4-scout-17b-16e-instruct` |
| `S3_ENDPOINT` | Endpoint S3 | `...` |
| `S3_ACCESS_KEY` | Access Key S3 | `...` |
| `S3_SECRECT_ACCESS_KEY` | Secret Key S3 | `...` |
| `S3_REGION` | Región S3 | `us-east-1` |
| `S3_BUCKET` | Bucket S3 | `asis-track` |
| `S3_PUBLIC_BASE_URL` | URL pública de S3 | `...` |
| `S3_PRESIGN_TTL` | TTL de presigned URLs | `3600` |

### `seguridad-service`

| Variable | Descripción | Ejemplo |
|---|---|---|
| `PORT` | Puerto interno | `8085` |
| `DB_URL` | JDBC URL de la DB | `jdbc:postgresql://db-seguridad.railway.internal:5432/asis_track_db` |
| `DB_USER` | Usuario PostgreSQL | `postgres` |
| `DB_PASSWORD` | Contraseña PostgreSQL | `password` |
| `MASTER_KEY_E` | Componente E de la clave maestra | `65537` |
| `MASTER_KEY_N` | Componente N de la clave maestra | `12345678901234567890` |
| `MASTER_KEY_D` | Componente D de la clave maestra | `98765432109876543210` |
| `INTERNAL_SECRET` | Secreto compartido entre microservicios | `microservice-internal-secret` |
| `JWT_SECRET_KEY` | Clave secreta JWT | `ThisIsAVeryLongSecretKey...` |
| `REDIS_HOST` | Host de Redis | `redis.railway.internal` |
| `REDIS_PORT` | Puerto de Redis | `6379` |

---

## Notas de Seguridad

- El `nginx-gateway` **solo expone** `GET /api/v1/security/keys/public` del `seguridad-service`.
- Los endpoints `/private`, `/rotate` y `/private/{id}` del `seguridad-service` **nunca** pasan por el gateway. Los microservicios los consumen directamente via **Private Networking** interna de Railway (`seguridad-service.railway.internal:8085`).
- Todos los backends (`usuarioservice`, `planilla-service`, `seguridad-service`) deben ser **Private** en Railway (sin dominio público).
---

## URLs del Gateway (Nginx)

| Ruta | Destino |
|---|---|
| `/api/v1/auth/**` | `usuarioservice` |
| `/api/v1/usuario-service/**` | `usuarioservice` |
| `/api/v1/planilla-service/**` | `planilla-service` |
| `/api/v1/security/keys/public` | `seguridad-service` (solo llave pública) |
