package co.edu.uceva.microservicioplanilla.domain.service.ai;

import org.springframework.stereotype.Component;

@Component
public class AiPromptFactory {

    public String buildStructureExtractionPrompt(String tiposPermitidos) {
        return """
            Analiza la imagen proporcionada. Detecta la estructura de la planilla física o digital.
            
            Devuelve ÚNICAMENTE un JSON con el siguiente formato, sin texto adicional:
            {
              "encabezados": [
                {
                  "nombre": "Nombre del encabezado",
                  "tipo_campo": "tipo_según_catálogo",
                  "opciones": ["opción1", "opción2"]
                }
              ]
            }
            
            Reglas:
            - "opciones" solo se incluye para tipos: combo, radio, multivaluecheckbox. Para el resto, omitir el campo.
            - Deduce el tipo usando ÚNICAMENTE estos valores:
            """ + tiposPermitidos;
    }

    public String buildTextRecognitionPrompt(String estructuraJson) {
        return """
            Analiza la imagen y extrae el contenido de cada celda de la tabla.
            
            La estructura de columnas es:
            """ + estructuraJson + """
            
            Devuelve ÚNICAMENTE un JSON con el siguiente formato, sin texto adicional:
            [
              { "columna": "Nombre columna", "fila": 1, "valor": "contenido extraído" },
              { "columna": "Nombre columna", "fila": 2, "valor": "contenido extraído" }
            ]
            
            Reglas:
            - Si una celda está vacía, usar valor null.
            - Las firmas devuelven su representación base64 como valor.
            - Respetar el número de filas exacto visible en la imagen.
            """;
    }
}
