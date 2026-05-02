package co.edu.uceva.microservicioplanilla.domain.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.io.InputStream;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service("groqAiService")
@AllArgsConstructor
public class GroqAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String getProviderName() {
        return "Groq (" + configService.getGroqModel() + ")";
    }

    @Override
    public String generateResponse(List<Resource> images) {
        String promptText = """
                    Analiza la imagen de la planilla adjunta y extrae la información de la tabla fila por fila.

                    Devuelve exclusivamente un arreglo JSON válido y sin formato adicional.

                    Reglas:

                    - ESTRUCTURA DE FILAS DINÁMICA: El JSON debe ser un arreglo []. Cada elemento representará una fila completa. Autodetecta los encabezados de la tabla en la imagen y transforma sus nombres a formato "snake_case" (minúsculas y guiones bajos) para usarlos como las claves (keys) de los objetos.
                    - CAMPOS COMPUESTOS (OBJETOS ANIDADOS): Si un encabezado principal agrupa sub-columnas que componen un solo dato (como fechas), no las pongas sueltas. Agrúpalas en un objeto anidado bajo la clave del encabezado principal detectado.
                    - CAMPOS DE SELECCIÓN (ÚNICA O MÚLTIPLE): Trata los campos que tienen opciones en sub-columnas como objetos anidados (igual que las fechas). Cada sub-columna de opción será una clave dentro de ese objeto y su valor debe ser un booleano (`true` o `false`).
                        - Evaluación de marcas: Si detectas cualquier tipo de marca en la celda correspondiente a esa opción (un círculo, una raya, un chulo/check, una "X", un garabato, etc.), asígnale el valor `true`. Si la celda está completamente en blanco, asígnale el valor `false`.
                    - EXTRACCIÓN LITERAL: Extrae los textos exactamente como aparecen en la imagen.
                    - CERO CORRECCIONES: NO corrijas ortografía ni mezclas extrañas de números/letras.
                    - VALORES VACÍOS Y FIRMAS: Si una celda de texto está vacía, devuelve un string vacío "". Para las columnas de firmas, detecta el encabezado y crea la clave en el JSON, pero asigna SIEMPRE un string vacío "" como su valor, independientemente de si hay trazos, garabatos o texto legible en la celda.
                    - FORMATO ESTRICTO: La respuesta DEBE empezar con "[" y terminar con "]". NO envuelvas la respuesta en bloques de código de Markdown (está estrictamente prohibido usar ```json o ```). No agregues NINGÚN texto explicativo antes ni después del JSON.

                    Esquema estructural esperado (las claves reales deben ser las que tú autodetectes en la imagen):

                    [
                      {
                        "nombre_columna_simple_1": "valor literal",
                        "nombre_columna_simple_2": "valor literal",
                        "nombre_encabezado_fecha_o_compuesto": {
                          "sub_columna_1": "valor",
                          "sub_columna_2": "valor"
                        },
                        "nombre_encabezado_seleccion": {
                          "opcion_1": false,
                          "opcion_2": true,
                          "opcion_3": false
                        },
                        "firma": ""
                      }
                    ]
                    """;
        return callGroqApi(images, promptText);
    }

    @Override
    public String extractStructure(List<Resource> images) {
        String promptText = """
                Analiza la imagen y detecta la estructura de la planilla, deduciendo además el tipo de campo digital ideal para cada columna o sección.

                Devuelve exclusivamente un JSON válido y sin formato adicional.

                Reglas:

                - No extraigas valores de las filas.
                - No inventes encabezados.
                - Detecta los encabezados visibles.
                - Conserva el orden de las columnas.
                - Deduce el tipo de componente digital que se necesita para cada encabezado. Debes clasificar el "tipo_campo" utilizando ÚNICAMENTE los siguientes valores permitidos en nuestro catálogo de componentes:
                    - "texto" (Para nombres, identificaciones, textos cortos)
                    - "numerico" (Para cantidades, números fijos)
                    - "fecha" (Para fechas en general)
                    - "desplegable" (Para seleccionar una opción de una lista, como motivos o estados)
                    - "checkbox" (Para aceptar términos o selecciones múltiples)
                    - "radio" (Para selección única entre 2 o 3 opciones, ej. Sí/No)
                    - "area_texto" (Para observaciones, descripciones largas o notas)
                    - "archivo" (Para carga de documentos adjuntos, fotos o evidencias)
                    - "firma" (Para firmas manuscritas táctiles)
                - EXTRACCIÓN DE OPCIONES: Si el "tipo_campo" deducido es "checkbox", "radio" o "desplegable", y las opciones están visibles de forma explícita en la imagen (por ejemplo, "Sí" y "No", o una lista de motivos), extrae esas opciones y agrégalas a un arreglo llamado "opciones". Si no hay opciones visibles, el arreglo debe estar vacío.
                - FORMATO ESTRICTO: La respuesta DEBE ser únicamente el objeto JSON. NO envuelvas la respuesta en bloques de código de Markdown (por ejemplo, no uses ```json o ```). No agregues texto antes ni después del JSON.

                Formato exacto esperado:

                {
                  "encabezados": [
                    {
                      "nombre": "Nombre del encabezado detectado",
                      "tipo_campo": "valor_del_catalogo",
                      "opciones": ["Opción 1", "Opción 2"] 
                    }
                  ]
                }
                """;
        return callGroqApi(images, promptText);
    }

    private String callGroqApi(List<Resource> images, String promptText) {
        String baseUrl = configService.getGroqUrl();
        String apiKey = configService.getGroqToken();
        String modelName = configService.getGroqModel();

        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Groq URL is not configured.");
        }
        if (apiKey == null || apiKey.isEmpty()) {
            throw new IllegalStateException("Groq API Key is not configured.");
        }

        try {
            // Read first image and convert to Base64
            Resource imageResource = images.get(0);
            byte[] imageBytes;
            try (InputStream is = imageResource.getInputStream()) {
                imageBytes = is.readAllBytes();
            }
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            // Construct exact JSON payload for Groq
            Map<String, Object> textContent = new HashMap<>();
            textContent.put("type", "text");
            textContent.put("text", promptText);

            Map<String, String> imageUrlMap = new HashMap<>();
            imageUrlMap.put("url", "data:image/jpeg;base64," + base64Image);

            Map<String, Object> imageContent = new HashMap<>();
            imageContent.put("type", "image_url");
            imageContent.put("image_url", imageUrlMap);

            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", List.of(textContent, imageContent));

            Map<String, Object> payload = new HashMap<>();
            payload.put("model", modelName);
            payload.put("messages", List.of(message));
            payload.put("temperature", 0.1);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

            // Ensure the URL ends with /chat/completions
            String endpoint = baseUrl.endsWith("/chat/completions") ? baseUrl : baseUrl + "/chat/completions";

            String responseJson = restTemplate.postForObject(endpoint, requestEntity, String.class);
            
            // Parse Groq response
            JsonNode rootNode = objectMapper.readTree(responseJson);
            JsonNode choices = rootNode.path("choices");
            if (choices.isArray() && choices.size() > 0) {
                return choices.get(0).path("message").path("content").asText();
            }
            return "Error: No content in Groq response.";

        } catch (IOException e) {
            throw new RuntimeException("Error processing image for Groq OCR", e);
        } catch (Exception e) {
            throw new RuntimeException("Error calling Groq API: " + e.getMessage(), e);
        }
    }
}
