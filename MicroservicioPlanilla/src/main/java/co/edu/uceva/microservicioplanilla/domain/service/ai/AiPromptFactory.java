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

    public String buildStructureFromImagePrompt(String tiposPermitidos) {
        return """
            Analiza la imagen de una planilla. Detecta únicamente los encabezados / columnas visibles.
            No extraigas datos de las filas, solo la estructura de la cabecera.
            Devuelve ÚNICAMENTE un JSON con el siguiente formato, sin texto adicional:
            [
              {
                "nombre_campo": "Nombre de la columna",
                "tipo_campo": "tipo_según_catálogo",
                "obligatorio": true/false,
                "opciones": ["opción1", "opción2"]
              }
            ]
            Reglas:
            - "opciones" solo se incluye para tipos: combo, radio, multivaluecheckbox. Para el resto, omitir el campo.
            - Deduce el tipo usando ÚNICAMENTE estos valores: """ + tiposPermitidos + """
            - "obligatorio": true si visualmente se identifica como requerido (*, negrita, marcador rojo, etc.), false por defecto.
            - Si la imagen no contiene una tabla o planilla clara, devolver un array vacío [].
            """;
    }

    public String buildPlanillaFromDescriptionPrompt(String descripcion, boolean crearEvento, String tiposPermitidos) {
        String eventoInstruccion = crearEvento ? """
            1. Propón un evento con los siguientes campos:
               - nombre_evento
               - descripcion_evento
               - fecha_hora_inicio (ISO-8601 o null)
               - fecha_hora_fin (ISO-8601 o null)
               - lugar_nombre (String o null)
            """ : """
            1. NO propongas un evento. Omitir toda la sección de evento.
            """;

        return """
            Basado en la siguiente descripción de un usuario, genera una propuesta de planilla.

            Descripción del usuario: """ + descripcion + """

            Instrucciones:
            """ + eventoInstruccion + """
            2. Propón la estructura de campos de la planilla como JSON:
            [
              {
                "nombre_campo": "...",
                "tipo_campo": "tipo_según_catálogo",
                "obligatorio": true/false,
                "opciones": ["..."]
              }
            ]

            Reglas:
            - Usa ÚNICAMENTE estos tipos: """ + tiposPermitidos + """
            - "opciones" solo para combo, radio, multivaluecheckbox. Omitir para otros tipos.
            - Campos comunes de asistencia/eventos: nombre, cédula, correo, firma, fecha, etc.
            - Devuelve ÚNICAMENTE el JSON solicitado, sin texto adicional.
            """;
    }
}
