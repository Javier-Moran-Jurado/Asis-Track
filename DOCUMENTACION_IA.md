# Documentación del Módulo de Inteligencia Artificial (OCR Multi-Modelo)

Este documento detalla la arquitectura, implementación y uso del subsistema de Inteligencia Artificial desarrollado para el microservicio de Planillas (`planilla-service`). Su principal objetivo es digitalizar imágenes de planillas de asistencia y extraer su estructura organizativa en un formato estructurado (JSON).

---

## 1. Arquitectura y Diseño

Para garantizar un sistema robusto, flexible y tolerante a fallos, el módulo de Inteligencia Artificial fue diseñado utilizando el **Patrón Strategy**, orquestado por un **Composite**. Esta arquitectura permite que el sistema "intercambie" dinámicamente entre distintos motores de Inteligencia Artificial (Hugging Face, Groq, OpenAI o Modelos Locales) según su disponibilidad, configuración o fallos de red.

### 1.1 Componentes Principales

- **`IAiModelService`**: Interfaz central que define el contrato base de cualquier modelo de IA dentro del sistema. Todo proveedor (Groq, OpenAI, etc.) implementa esta interfaz exponiendo el método `generateResponse(List<Resource> images)`.
- **`DynamicAiConfigService`**: Servicio encarcado de inyectar las credenciales y parámetros de los proveedores desde las variables de entorno (`application.yml` o `.env`). Este servicio retiene la configuración actual en memoria y permite modificarla en caliente (Runtime).
- **`CompositeAiService`**: Es el cerebro orquestador. Intercepta todas las peticiones OCR entrantes, evalúa a qué proveedor enviarlas (según lo indicado por el administrador en el `DynamicAiConfigService`), y si el proveedor activo llega a fallar (por caídas, rate-limits, etc.), ejecuta automáticamente una estrategia de contingencia (*Fallback*) hacia el proveedor local `Ollama`.
- **`AiConfigRestController`**: Exposición REST para que un administrador cambie las credenciales y el proveedor primario en tiempo real.

---

## 2. Proveedores de IA Implementados

El sistema ha sido adaptado para soportar los siguientes ecosistemas, cada uno con una implementación a la medida:

### 2.1 Groq (Implementación Nativa RestTemplate)
**Servicio:** `GroqAiServiceImpl`
- **Enfoque:** Construido usando `RestTemplate` directamente hacia la API compatible de Groq (`https://api.groq.com/openai/v1/chat/completions`). 
- **Razón:** Groq posee una implementación rápida de inferencia en hardware LPU. Sin embargo, su endpoint visual no siempre es compatible de forma plug-and-play con ciertas dependencias de *Spring AI*, por lo cual se adaptó un cliente manual y optimizado.
- **Propósito:** Ejecuta un prompt robusto *zero-shot* que **extrae toda la tabla fila por fila**. Transforma dinámicamente los encabezados detectados a formato `snake_case`, estructura campos compuestos y fechas como objetos anidados, detecta marcas en casillas transformándolas en valores booleanos (`true`/`false`), y estandariza los campos vacíos y firmas. El resultado final es un arreglo JSON estricto listo para ser persistido.

### 2.2 Hugging Face (Modelos PaaS / Zai)
**Servicio:** `HuggingFaceAiServiceImpl`
- **Enfoque:** Diseñado para consumir APIs dedicadas de *Layout Parsing* y extracción (como `GLM-OCR`).
- **Propósito:** Excelente para análisis OCR clásico debido a que se especializa en "document parsing" puro.

### 2.3 OpenAI (Cloud)
**Servicio:** `OpenAiServiceImpl`
- **Enfoque:** Implementado usando el ecosistema `Spring AI`. Permite interactuar nativamente con la gama `gpt-4o-mini` o superior, integrando capacidades multimodales avanzadas.

### 2.4 Ollama (Fallback Local)
**Servicio:** `OllamaAiServiceImpl`
- **Enfoque:** Conecta con una instancia local de Ollama (ej. LLaVA). 
- **Propósito:** Actúa como red de seguridad. Si el sistema primario pierde acceso a Internet o la API colapsa, Ollama atiende el OCR garantizando 100% de disponibilidad (*Zero Downtime OCR*).

---

## 3. Variables de Entorno Clave (`.env`)

Para arrancar el contenedor o servicio localmente, estas son las principales configurables:

```env
# Define quién procesará el OCR primero (Valores: groq, hf, cloud, ollama)
AI_PRIMARY_PROVIDER=groq

# Groq Config
GROQ_URL=https://api.groq.com/openai/v1
GROQ_TOKEN=gsk_your_token_here
GROQ_MODEL=meta-llama/llama-4-scout-17b-16e-instruct

# OpenAI Config
OPENAI_BASE_URL=https://api.openai.com
OPENAI_API_KEY=sk-your_token_here
AI_CLOUD_MODEL=gpt-4o-mini
```

---

## 4. Tutorial de Uso de Endpoints

### 4.1. Digitalizar Planilla (OCR)
Punto de entrada principal para que los usuarios (Docentes, Coordinadores, etc.) envíen sus capturas para su transcripción y estructuración.

- **URL:** `POST /api/v1/planilla-service/planillas/digitalizar`
- **Roles Permitidos:** `[Administrador, Coordinador, Decano, Docente, Monitor]`
- **Consumo:** `multipart/form-data`

**Parámetros:**
- `file` (Obligatorio, tipo Archivo): Una imagen `.jpg`, `.png` o `.pdf`.

**Ejemplo de Petición cURL:**
```bash
curl -X POST "http://localhost:8084/api/v1/planilla-service/planillas/digitalizar" \
     -H "Authorization: Bearer <TU_TOKEN_JWT>" \
     -F "file=@/ruta/a/tu/planilla.jpg"
```

**Respuesta Exitosa (Procesado por Groq con Estructura de Datos):**
```json
[
  {
    "cedula": "111222333",
    "nombres": "Juan Perez",
    "fecha_asistencia": {
      "dia": "14",
      "mes": "04",
      "anio": "2026"
    },
    "opciones_menu": {
      "vegetariano": false,
      "normal": true
    },
    "firma": ""
  }
]
```

---

### 4.2. Configuración Dinámica de la IA (Administradores)

Endpoints exclusivos para supervisar o intervenir la forma en la que la Inteligencia Artificial procesa la información sin requerir reinicios.

#### A) Ver Configuración Actual
- **URL:** `GET /api/v1/planilla-service/ai-config`
- **Roles Permitidos:** `[Administrador]`

**Ejemplo de Respuesta:**
```json
{
    "activeProvider": "groq",
    "cloudBaseUrl": "https://api.openai.com",
    "cloudApiKey": "********",
    "cloudModelName": "gpt-4o-mini",
    "hfUrl": "https://router.huggingface.co/zai-org/api/paas/v4/layout_parsing",
    "hfToken": "********",
    "ollamaBaseUrl": "http://localhost:11434",
    "groqUrl": "https://api.groq.com/openai/v1/chat/completions",
    "groqToken": "********",
    "groqModel": "meta-llama/llama-4-scout-17b-16e-instruct"
}
```

#### B) Actualizar Proveedor o Modelos en Tiempo Real
- **URL:** `POST /api/v1/planilla-service/ai-config`
- **Roles Permitidos:** `[Administrador]`
- **Content-Type:** `application/json`

Puedes enviar únicamente las llaves que deseas actualizar. Si quieres cambiar de `groq` a la nube de OpenAI (`cloud`) al instante porque se acabaron los créditos:

**Ejemplo de Petición (Cambio a OpenAI):**
```bash
curl -X POST "http://localhost:8084/api/v1/planilla-service/ai-config" \
     -H "Authorization: Bearer <TU_TOKEN_JWT>" \
     -H "Content-Type: application/json" \
     -d '{
           "activeProvider": "cloud",
           "cloudModelName": "gpt-4o",
           "cloudApiKey": "sk-NUEVA_API_KEY"
         }'
```

**Ejemplo de Petición (Cambio de Modelo de Groq):**
```bash
curl -X POST "http://localhost:8084/api/v1/planilla-service/ai-config" \
     -H "Authorization: Bearer <TU_TOKEN_JWT>" \
     -H "Content-Type: application/json" \
     -d '{
           "activeProvider": "groq",
           "groqModel": "llama-3.2-90b-vision-preview"
         }'
```

**Respuesta Exitosa:**
```json
{
  "message": "AI Configuration updated successfully"
}
```

---
> **Nota de Seguridad:** Siempre que un cliente solicite la configuración mediante el método `GET`, el sistema enmascara (oculta con `********`) automáticamente los tokens como medida de protección de llaves sensibles ante fugas de log o MITM.

---

## 5. Guía: Cómo cambiar el Proveedor de IA Activo

Existen dos maneras de indicarle al sistema qué Inteligencia Artificial debe procesar las imágenes: una persistente (mediante entorno) y una dinámica (mediante API).

### Método 1: Cambio Persistente (vía archivo `.env`)
Ideal para establecer el proveedor por defecto cada vez que el sistema se reinicia.

1. Abre el archivo `.env` en la raíz de tu proyecto.
2. Localiza la variable `AI_PRIMARY_PROVIDER`.
3. Cambia su valor a uno de los proveedores soportados:
   - `groq` (Recomendado para el prompt actual)
   - `cloud` (Para OpenAI)
   - `hf` (Para Hugging Face)
   - `ollama` (Para procesamiento local)
4. Ejemplo: `AI_PRIMARY_PROVIDER=cloud`
5. Reinicia el contenedor del microservicio de planillas para aplicar los cambios:
   `docker compose up -d --build planilla-service`

### Método 2: Cambio Dinámico (vía Endpoint REST)
Ideal para cambiar de proveedor "en caliente" sin tener que reiniciar el servidor (por ejemplo, si te quedas sin créditos de Groq en medio de la operación y quieres pasar a OpenAI).

1. Consigue tu token JWT con rol de **Administrador**.
2. Haz una petición `POST` al endpoint `/api/v1/planilla-service/ai-config`.
3. En el body JSON, envía la propiedad `"activeProvider"` con el nombre del nuevo proveedor.
   
**Ejemplo (Cambiando a OpenAI instantáneamente):**
```bash
curl -X POST "http://localhost:8084/api/v1/planilla-service/ai-config" \
     -H "Authorization: Bearer <TU_TOKEN_JWT>" \
     -H "Content-Type: application/json" \
     -d '{
           "activeProvider": "cloud"
         }'
```
*A partir de ese instante, la siguiente planilla será escaneada usando OpenAI (asumiendo que las credenciales de OpenAI ya estaban configuradas).*
