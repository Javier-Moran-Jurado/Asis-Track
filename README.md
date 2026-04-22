# AsisTrack – Archivos, firma táctil y QR (prototipo móvil)

Pantalla que integra tres funcionalidades: carga de archivos con previsualización, captura de firma manuscrita y visualización/generación de códigos QR.

##  Diseño en Figma

<img width="1556" height="1453" alt="Frame 21" src="https://github.com/user-attachments/assets/0c703f36-d71f-4ef3-9b1a-92d5818cc421" />
<img width="371" height="1953" alt="Frame 22" src="https://github.com/user-attachments/assets/b2bc905e-3d0b-46fb-8552-96ca2342f904" />

---

## Criterios de aceptación

- Interfaz de carga de archivos (PDF, PNG, JPG, ZIP) con previsualización, indicadores de progreso y selección múltiple.
- Lienzo para captura de firma táctil con botones: limpiar, aceptar, cancelar.
- Pantalla de visualización de QR generado y pantalla de escáner con overlay.
- Diseño responsive (mobile‑first) con tamaños táctiles.

---

## Componentes incluidos

### 1. Carga de archivos
- Área de selección múltiple.
- Lista dinámica de archivos con nombre, tamaño y barra de progreso simulada.
- Previsualización de imágenes (miniaturas).

### 2. Firma táctil
- Lienzo interactivo (funciona con ratón y dedo).
- Botón *Limpiar* (borra el dibujo).
- Botón *Aceptar* (simula guardado).
- Botón *Cancelar* (restablece la firma).

### 3. Códigos QR
- *Generador:* campo de texto + botón → cambia la visualización del QR simulado.
- *Escáner:* overlay con marco de cámara simulado y botón “Simular escaneo” (muestra un mensaje con datos leídos).

---

## Vista móvil

- Todos los elementos tienen altura táctil mínima de 44‑48px.
- El canvas de firma responde a eventos táctiles.
- La carga de archivos y el escáner se apilan en columna en móvil y se disponen en fila en tablet/escritorio.
