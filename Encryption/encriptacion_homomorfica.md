# Sistema de Encriptacion Homomorfica: Arquitectura y Funcionalidad

Este documento describe la arquitectura y el funcionamiento del sistema de encriptacion y desencriptacion homomorfica integrado en la libreria `Encryption`. La logica se basa en el articulo cientifico *"Text encryption for lower text size: Design and implementation"* de Vishnoi et al.

## 1. Fundamentos Tecnicos y Mapeo Criptografico

El sistema implementa un esquema criptografico con las siguientes caracteristicas:
1. **Arquitectura de Secuencia (4-Inputs)**: Se implementa una topologia de multiples etapas donde la informacion se procesa en bloques (chunks) de 4 bytes simultaneos a traves de capas en cascada.
2. **Secuencia de Conjuntos**: Utiliza una secuencia de conjuntos $A(r)$ de longitud $R$ basada en potencias de dos, disenada para mantener la propiedad de no-determinismo inyectando aleatoriedad a cada byte antes de la transformacion matricial.
3. **Operadores Logicos**: La transformacion entre etapas se realiza exclusivamente cruzando pares de bytes mediante los operadores de **union** (`|` simulando $U$) y **diferencia simetrica** (`^` simulando $\Delta$).
4. **Eficiencia de Espacio**: El tamano del texto cifrado y de la clave generada son identicos al tamano del texto original (proporcion 1:1), gracias a la reconstruccion guiada de entropia perdida en operaciones no inversibles de union.
5. **Control de Entropia Homomorfica**: Se utilizan elementos de 6 bits encendidos produciendo entropia matematica de 2.

### Implementacion en Java

Para la manipulacion de flujos de datos (`byte[]`), se aplican las siguientes reglas:

* **Mascaras de Bits (Conjuntos A)**: Se emplea una secuencia estatica de mascaras de bits.
* **Metricas de Entropia**: Al utilizar mascaras que limitan los estados posibles de cada byte a 4 valores dentro del conjunto cifrado, se logra una entropia matematica de **2 bits** por byte.
* **Mapeo de Operadores**:
   * **Union**: Implementada mediante el operador bitwise OR (`|`).
   * **Diferencia Simetrica**: Implementada mediante el operador bitwise XOR (`^`).

### Procesos Criptograficos

El sistema itera sobre la entrada separandola en **bloques de 4 bytes** ($P_0, P_1, P_2, P_3$):
1. **Enmascaramiento Aleatorio**: A cada byte del bloque se le inyecta una variante no deterministica con un elemento aleatorio $A_r$.
2. **Cifrado Multi-Etapa ($C$)**: Los 4 bytes pasan por dos iteraciones de entrelazado cruzado usando `|` y `^`, produciendo 4 salidas para el cifrado ($Y$).
3. **Proyeccion y Generacion de Clave ($K$)**: Internamente, el codigo proyecta el cifrado para producir una salida pre-calculo ($Z$). La llave se extrae como $K = P \oplus Z$.
4. **Descifrado**: Se reconstruye el estado vector $Z$ y se recupera el mensaje con $P = Z \oplus K$.

## 2. Estructura del Sistema

Los componentes principales que integran esta funcionalidad son:

* **Clase `HomomorphicEncryptionResponse`** en `src/main/java/co/uceva/edu/security/homomorphic/HomomorphicEncryptionResponse.java`.
* **Clase `HomomorphicEncryption`** en `src/main/java/co/uceva/edu/security/homomorphic/HomomorphicEncryption.java`.

## 3. Uso Basico

```java
byte[] plaintext = "Informacion Confidencial".getBytes(StandardCharsets.UTF_8);
byte[] aSets = new byte[]{(byte) 0xFC, (byte) 0xF3, (byte) 0xCF, (byte) 0x3F, (byte) 0x7E, (byte) 0xF9, (byte) 0xE7, (byte) 0x9F};

HomomorphicEncryptionResponse result = HomomorphicEncryption.encrypt(plaintext, aSets);

byte[] recovered = HomomorphicEncryption.decrypt(result.getCiphertext(), result.getKey());
String original = new String(recovered, StandardCharsets.UTF_8);
```