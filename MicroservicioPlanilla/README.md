# Microservicio Planilla - Módulo de Digitalización AI

Este documento describe los resultados obtenidos durante las pruebas del endpoint de digitalización (`/api/v1/planilla-service/planillas/digitalizar`) que utiliza un modelo de IA (Ollama) para extraer información manuscrita e impresa de las planillas de asistencia en formato de imagen, así como las métricas de precisión y oportunidades de mejora a futuro.

## Evaluación de Precisión (Tasa de Aciertos)

Durante la evaluación empírica utilizando imágenes reales de pruebas (`testImages/2026-04-14_082294-1.jpg`), se observaron los siguientes resultados en la transcripción:

1. **Reconocimiento de Estructura (Alto)**
   * El modelo detecta correctamente el formato tabular, identificando los encabezados principales (Cédula, Nombres, Apellidos, Código, Dependencia, Firma).
   * La separación por filas y columnas se mantiene a nivel semántico de forma muy acertada.

2. **Reconocimiento Numérico - Cédulas y Códigos (Medio-Alto)**
   * Los números de cédula (`1117349510`, `1118656814`, `1122512501`) tienen un alto índice de acierto (cercano al **90%**).
   * Algunos formatos con puntos (ej. `1.112.1401.490`) se identifican bien pero requieren normalización.
   * Los códigos de estudiantes muestran buena retención, aunque caligrafías muy enredadas causan falsos números.

3. **Reconocimiento de Texto Manuscrito - Nombres y Apellidos (Medio)**
   * Tasa de acierto estimada: **65% - 75%**.
   * Caligrafías complejas introducen variaciones en letras individuales ("MOBAN" en lugar de "Moran", "Scurz", "Cedilian Gimule").
   * Los nombres muy largos o con combinaciones complejas tienden a fusionar "Nombres" con "Apellidos".

4. **Tratamiento de Firmas (Bajo)**
   * El modelo intenta "leer" e interpretar las firmas como texto plano (ej. transcribe firmas ilegibles como "Javier Gran" repetidamente o "Andres Z").

---

##  Posibles Mejoras a Futuro

Para lograr un ambiente de producción robusto y elevar la tasa de aciertos por encima del 95%, se recomiendan implementar las siguientes estrategias:

### 1. Mejoras en la Configuración del Modelo AI (Prompt Engineering)
* **Retorno Estructurado Obligatorio:** Ajustar el prompt para forzar al LLM a responder **exclusivamente** en formato `JSON`, en lugar de texto plano libre.
* **Instrucciones Restrictivas:** Indicar explícitamente al modelo: *"Ignora la columna de firmas, no intentes transcribirla"* o *"Retorna nulo si la letra es completamente ilegible"*.

### 2. Pre-procesamiento de Imágenes (Computer Vision)
* **Ajuste de Contraste y Binarización:** Utilizar librerías (ej. OpenCV) para escalar la imagen, limpiar el ruido de fondo, ajustar la iluminación y convertir a blanco y negro antes de enviarla a Ollama.
* **Alineación (Deskew):** Corregir el ángulo de rotación de fotografías tomadas con celulares para facilitar la tarea del OCR.

### 3. Post-procesamiento y Validación
* **Limpieza de Datos (Sanitization):** Aplicar expresiones regulares en el Backend (Java) sobre los números de cédulas devueltos para remover puntos o caracteres alfanuméricos colados.
* **Fuzzy Matching contra Base de Datos:** Comparar los "nombres" y "apellidos" extraídos con la base de datos de usuarios matriculados. Si el OCR extrae "Javie Movan" pero en BD existe "Javier Moran" bajo esa cédula, hacer la autocorrección automática.

### 4. Upgrade Tecnológico
* Probar y desplegar modelos base de OCR más especializados en manuscritos (Vision-Language Models como `LLaVA` con una cuantización superior o usar APIs cloud como Google Cloud Vision / Amazon Textract) si Ollama se queda corto en casos de caligrafía extrema.
