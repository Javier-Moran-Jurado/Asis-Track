# Diseño de Dashboard con Filtros Dinámicos (Web y Móvil)

Este apartado presenta el diseño visual de un dashboard de estadísticas, desarrollado en Figma a partir de estructuras HTML y CSS.  
El enfoque principal es la visualización de datos mediante indicadores (KPIs) y gráficos, junto con filtros por período.

---

## Vista Web - Dashboard

<img width="1253" height="472" alt="Frame 16" src="https://github.com/user-attachments/assets/f1683504-ce37-4b62-8490-fec12a0e4a9d" />

### Descripción

Se diseñó una interfaz tipo dashboard que incluye:

- Indicadores principales (KPIs):
  - Total de planillas
  - Asistencia
  - Pendientes
  - Errores

- Gráficas:
  - Barras (categorías de planillas)
  - Circular (distribución general)

- Filtro por período:
  - Semanal
  - Mensual
  - Anual

El diseño mantiene una estructura limpia, con tarjetas, sombras suaves y jerarquía visual clara.

---

## Vista Móvil - Dashboard

<img width="415" height="1045" alt="Frame 15" src="https://github.com/user-attachments/assets/024d8138-873e-4a09-89cf-f3a97e3bbcc7" />


### Descripción

Se adaptó el diseño a dispositivos móviles con:

- Layout en columna única
- Componentes apilados verticalmente
- Filtros tipo "chips" desplazables horizontalmente
- Gráficas optimizadas para pantallas pequeñas

Se prioriza la legibilidad y el acceso rápido a la información.

---

## Características del Diseño

- Diseño moderno basado en tarjetas (card-based UI)
- Uso de colores semánticos:
  - Azul → información principal
  - Verde → estado positivo
  - Amarillo → pendientes
  - Rojo → errores

- Tipografía clara y jerarquizada
- Espaciado consistente
- Componentes reutilizables

---

## Comportamiento Visual (Simulado)

El dashboard incluye un sistema de filtros por período:

- Al seleccionar una opción (Semanal, Mensual o Anual):
  - Cambian los valores de los KPIs
  - Se actualizan las gráficas
  - Se modifica la distribución de datos

Este comportamiento fue simulado a nivel visual sin uso de JavaScript, manteniendo compatibilidad con herramientas de diseño como Figma.

---

## 🧩 Tecnologías utilizadas

- HTML5
- CSS3
- Figma (para diseño y prototipado)

---

## 📌 Notas

- Este desarrollo corresponde únicamente a la capa visual (UI)
- No incluye lógica de backend ni conexión a datos reales
- El objetivo es representar de forma clara la estructura y experiencia del usuario

---
