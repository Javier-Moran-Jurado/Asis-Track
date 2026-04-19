# Asis-Track

Esta es una prueba modificando este documento para comprobar el pull_request

---
## Implementacion de ia para reconocimiento de texto (OCR)

Para la extracción de texto de planillas con texto impreso y manuscritos históricos, hemos implementado una solución local y eficiente utilizando **Ollama**.

Tras evaluar el rendimiento de varios modelos populares, seleccionamos **`glm-ocr`** como nuestra herramienta principal. Este modelo destacó por dos razones fundamentales:
* **Velocidad:** Entrega resultados consistentes en una franja de 1 a 10 segundos.
* **Precisión:** Demostró una capacidad superior para interpretar caligrafía y preservar correctamente los caracteres especiales del español (como la 'ñ' y las tildes).

* **[Documentacion detallada de la implementación, el entorno de pruebas en Colab y los ejemplos de peticiones JSON en OCRImpl.md](OCRImpl.md)**