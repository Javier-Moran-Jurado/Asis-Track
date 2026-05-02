package co.edu.uceva.microservicioplanilla.domain.service;

import co.edu.uceva.microservicioplanilla.utils.ImagePreprocessor;
import co.edu.uceva.microservicioplanilla.utils.SpellCheckerUtil;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.content.Media;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.util.MimeTypeUtils;

import java.util.List;

@Service("cloudAiService")
@AllArgsConstructor
public class OpenAiServiceImpl implements IAiModelService {

    private final DynamicAiConfigService configService;

    @Override
    public String getProviderName() {
        return "Cloud API (OpenAI Compatible - " + configService.getCloudModelName() + ")";
    }

    @Override
    public String generateResponse(List<Resource> images) {
        String promptText = """
                Text Recognition: Extrae todo el texto de la imagen y entrégalo en el formato JSON esperado.
                """;
        return callOpenAiApi(images, promptText);
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
        return callOpenAiApi(images, promptText);
    }

    private String callOpenAiApi(List<Resource> images, String promptText) {
        String baseUrl = configService.getCloudBaseUrl();
        String apiKey = configService.getCloudApiKey();
        
        if (baseUrl == null || baseUrl.isEmpty()) {
            throw new IllegalStateException("Cloud API Base URL is not configured.");
        }

        OpenAiApi api = OpenAiApi.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .build();
                
        OpenAiChatModel dynamicModel = OpenAiChatModel.builder()
                .openAiApi(api)
                .build();

        StringBuilder fullText = new StringBuilder();

        for (Resource image : images) {
            try {
                // 1. Preprocesar imagen
                Resource processedImg = ImagePreprocessor.preprocessImage(image);

                // 2. Crear mensaje
                UserMessage userMessage = UserMessage.builder()
                        .text(promptText)
                        .media(List.of(new Media(MimeTypeUtils.IMAGE_JPEG, processedImg)))
                        .build();

                // 3. Configurar opciones del modelo
                OpenAiChatOptions options = OpenAiChatOptions.builder()
                        .model(configService.getCloudModelName())
                        .temperature(0.0)
                        .build();

                // 4. Llamar al modelo
                ChatResponse response = dynamicModel.call(new Prompt(userMessage, options));

                if (response != null && response.getResult() != null) {
                    String rawText = response.getResult().getOutput().getText();
                    // 5. Corrección ortográfica
                    String corrected = SpellCheckerUtil.correctText(rawText);
                    fullText.append(corrected).append("\n\n");
                }
            } catch (Exception e) {
                throw new RuntimeException("Error en Cloud API: " + e.getMessage(), e);
            }
        }
        return fullText.toString().trim();
    }
}
