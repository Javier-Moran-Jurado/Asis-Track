# Sistema de Encriptación Homomórfica: Arquitectura y Funcionalidad

Este documento describe la arquitectura y el funcionamiento del sistema de encriptación y desencriptación homomórfica integrado en el proyecto. La lógica se basa en el artículo científico *"Text encryption for lower text size: Design and implementation"* de Vishnoi et al., adaptado para su uso en este microservicio.

## 1. Fundamentos Técnicos y Mapeo Criptográfico

El sistema implementa un esquema criptográfico con las siguientes características:
1. **Arquitectura de Secuencia (4-Inputs)**: Se implementa una topología de múltiples etapas donde la información se procesa en bloques (chunks) de 4 bytes simultáneos a través de capas en cascada (Fig. 1 y Fig. 2). [Lógica de agrupación y padding](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L30)
2. **Secuencia de Conjuntos**: Utiliza una secuencia de conjuntos $A(r)$ de longitud $R$ basada en potencias de dos, diseñada para mantener la propiedad de no-determinismo inyectando aleatoriedad a cada byte antes de la transformación matricial. [Definición de Máscaras A(r)](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L11)
3. **Operadores Lógicos**: La transformación entre etapas se realiza exclusivamente cruzando pares de bytes mediante los operadores de **unión** (`|` simulando $U$) y **diferencia simétrica** (`^` simulando $\Delta$). [Capas de transformación](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L39)
4. **Eficiencia de Espacio**: El tamaño del texto cifrado y de la clave generada son idénticos al tamaño del texto original (proporción 1:1), gracias a la reconstrucción guiada de entropía perdida en operaciones no inversibles de unión. [Asignación de Memoria](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L27)
5. **Control de Entropía Homomórfica**: Se utilizan elementos de 6 bits encendidos produciendo entropía matemática de 2. El sistema iterativamente asegura que una entrada en texto plano mapee en salidas de cifrado variantes y no-determinísticas.

### Implementación en Java

Para la manipulación de flujos de datos (`byte[]`), se aplican las siguientes reglas:

* **Máscaras de Bits (Conjuntos A)**: Se emplea una secuencia estática de máscaras de bits. Cada máscara actúa como un conjunto donde la configuración de bits encendidos y apagados define el espacio de entropía.
* **Métricas de Entropía**: Al utilizar máscaras que limitan los estados posibles de cada byte a 4 valores dentro del conjunto cifrado, se logra una entropía matemática de **2 bits** por byte.
* **Mapeo de Operadores**:
   * **Unión**: Implementada mediante el operador bitwise OR (`|`).
   * **Diferencia Simétrica**: Implementada mediante el operador bitwise XOR (`^`).

### Procesos Criptográficos

El sistema itera sobre la entrada separándola estricta y funcionalmente en **bloques de 4 bytes** ($P_0, P_1, P_2, P_3$):
1. **Enmascaramiento Aleatorio**: A cada byte del bloque se le inyecta una variante no determinística con un elemento aleatorio $A_r$ usando la fórmula de enmascaramiento. [Ver código](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L34)
2. **Cifrado Multi-Etapa ($C$)**: Los 4 bytes pasan por dos iteraciones de entrelazado cruzado usando los operadores `|` (Union) y `^` (Symmetric Difference) (según la disposición de la *Fig. 1* del paper metodológico), produciendo 4 salidas para el cifrado ($Y$). [Ver implementación](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L39)
3. **Proyección y Generación de Clave ($K$)**: Internamente, el código proyecta el cifrado evaluándolo a través de la red de resolución ($\Delta$ constante) de la *Fig. 2* para producir una salida pre-cálculo ($Z$). La llave que repara la destrucción entrópica de la primera capa se extrae como $K = P \oplus Z$, logrando una llave $1:1$ proporcional al mensaje. [Ver derivación](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L51)
4. **Descifrado**: Invertir y regenerar el mensaje original procesa el texto cifrado nuevamente a través de la arquitectura topológica completa de la *Fig. 2* para reconstruir exitosamente el estado vector $Z$. Luego, el mensaje decodificado irrumpe al enfrentar este estado contra la llave guardada ($P = Z \oplus K$). [Ver recuperación](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java#L79)

---

## 2. Estructura del Sistema

Los componentes principales que integran esta funcionalidad son:

* **[Clase HomomorphicEncryptionResponse](src/main/java/co/edu/uceva/microservicioplanilla/domain/model/HomomorphicEncryptionResponse.java)**: Objeto de transferencia de datos (DTO) diseñado para encapsular el texto cifrado y la clave generada.
* **[Servicio HomomorphicEncryptionService](src/main/java/co/edu/uceva/microservicioplanilla/domain/service/HomomorphicEncryptionService.java)**: Componente donde reside la lógica central del algoritmo, incluyendo las definiciones de las máscaras de bits y los métodos de transformación.
* **[Controlador PlanillaRestController](src/main/java/co/edu/uceva/microservicioplanilla/delibery/rest/PlanillaRestController.java)**: Punto de entrada del API que intercepta los metadatos de las planillas para aplicar el proceso de cifrado antes de su persistencia.

---

## 3. Flujo de Operación del Sistema

El proceso estándar para la protección de metadatos sigue estos pasos:

1. **Recepción**: El sistema recibe una entidad `Planilla` a través de una petición de guardado.
2. **Procesamiento**: El controlador identifica la presencia de metadatos y los convierte a formato binario (`UTF-8`).
3. **Transformación**:
    - El servicio de encriptación procesa el flujo en trozos de a 4 bytes, aplicando máscaras aleatorias y la red bidimensional de operadores.
    - Se generan iterativamente dos arreglos de bytes procesados: el mensaje cifrado y la clave de descifrado, ambos respetando rigurosamente la longitud original exacta.
4. **Codificación y Persistencia**:
    - Ambos arreglos se codifican en formato **Base64** para garantizar su integridad durante el transporte y almacenamiento.
    - Los valores se concatenan utilizando un delimitador (`:`) y se almacenan en el campo `metadatos`.
5. **Almacenamiento**: La entidad se guarda en la base de datos con sus metadatos protegidos.

---

## 4. Interacción con el API (Ejemplos)

### Registro de una Planilla con Metadatos Protegidos

Para registrar una planilla con información confidencial, se debe realizar una petición al endpoint de planillas.

```bash
curl -X POST http://localhost:8080/api/v1/planilla-service/planillas \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <TOKEN_JWT>" \
     -d '{
           "fechaHoraInicio": "2026-05-10T10:00:00",
           "fechaHoraFin": "2026-05-10T12:00:00",
           "lugar": "Sede Administrativa",
           "metadatos": "Información Confidencial"
         }'
```

**Estado del Registro en Base de Datos:**
El campo `metadatos` almacenará una cadena compuesta por el cifrado y la llave en Base64:
```json
{
  "id": 1,
  "metadatos": "VmFsaWRhY2lvbt==:M3hlcnR5dWlvcA==",
  ...
}
```

### Recuperación y Descifrado de Información

Para consumir la información protegida desde la lógica del negocio, se debe decodificar el campo de metadatos.

```java
// Obtención de la entidad
Planilla planilla = planillaService.findById(id);

// Separación de componentes
String[] partes = planilla.getMetadatos().split(":");
byte[] cifrado = Base64.getDecoder().decode(partes[0]);
byte[] llave = Base64.getDecoder().decode(partes[1]);

// Descifrado
byte[] plano = homomorphicEncryptionService.decrypt(cifrado, llave);
String informacionRecuperada = new String(plano, StandardCharsets.UTF_8);
```
