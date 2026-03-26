# Asis-Track

Aquí tienes el contenido sin emojis, listo para copiar y pegar:

---

¿Qué hace el proyecto?

Asis-Track UCEVA es una plataforma integral (web + app móvil) que digitaliza las miles de planillas físicas de asistencia que actualmente acumula la universidad en clases, eventos, tutorías, créditos de bienestar y préstamos de laboratorios. La plataforma ofrece una alternativa moderna de registro digital mediante formularios en app y códigos QR con geolocalización. Toda la información se consolida en bases de datos estructuradas y se potencia con análisis estadístico para generar reportes automáticos y visualización de indicadores que apoyan la toma de decisiones institucionales. Adicionalmente, incorpora un sistema de cifrado híbrido (RC4 + Blowfish + ECDH + MD5) para garantizar la seguridad de los datos en tránsito y almacenamiento.

---

¿Por qué el proyecto es útil?

El proyecto transforma un problema administrativo cotidiano en una solución estratégica para la UCEVA. Actualmente, la universidad acumula miles de planillas físicas en archivos de secretarías académicas, Bienestar Universitario, laboratorios y biblioteca, lo que genera:

- Pérdida de memoria institucional: Los datos históricos sobre asistencia, participación estudiantil y uso de recursos están "atrapados" en papel e inaccesibles para análisis.
- Ineficiencia operativa: Horas perdidas en buscar información en papel, archivos desordenados y duplicación de esfuerzos.
- Riesgo en acreditaciones: Los procesos de acreditación requieren datos históricos confiables que actualmente no están disponibles de forma ágil.
- Espacio físico ocupado: Archiveros completos dedicados a almacenar papel que podría digitalizarse.
- Riesgo de deterioro o pérdida: El papel se degrada, extravía o destruye, perdiendo información crítica.

Asis-Track resuelve estos problemas digitalizando toda la información histórica, modernizando los procesos actuales de registro y proporcionando dashboards con tendencias históricas y actuales que apoyan la eficiencia operativa y los procesos de acreditación.

---

¿Cómo pueden comenzar los usuarios con el proyecto?

Para administrativos y docentes:
1. Solicitar credenciales de acceso al área de Sistemas de la UCEVA.
2. Acceder a la plataforma web a través de https://asis-track.uceva.edu.co.
3. Para digitalización de planillas existentes: escanear las planillas físicas y subirlas al sistema; el módulo de IA extraerá los datos automáticamente y un panel de validación permitirá corregir cualquier error.
4. Para registro digital: desde la app móvil o web, seleccionar el tipo de evento (clase, préstamo, bienestar), generar el código QR dinámico y registrar asistencias.

Para estudiantes:
1. Descargar la app Asis-Track desde las tiendas oficiales (Play Store / App Store).
2. Iniciar sesión con credenciales institucionales.
3. Escanear códigos QR en clases o eventos para confirmar asistencia.
4. Consultar historial de asistencias y justificar inasistencias subiendo soportes desde la app.

Requisitos técnicos:
- Web: Navegador actualizado (Chrome, Firefox, Edge, Safari).
- App móvil: Android 8.0+ o iOS 13+.
- Conexión a internet: Estable para sincronización de datos.

---

¿Quién mantiene y contribuye con el proyecto?

El proyecto Asis-Track UCEVA es mantenido y desarrollado por un equipo de profesionales de la Universidad del Valle del Cauca, con roles y responsabilidades definidas dentro del marco de trabajo ágil Scrum.

- Product Owner / Full Stack: Andrés David Guevara Martínez
  Responsabilidades: Lidera la definición del producto, gestiona el backlog priorizando funcionalidades según el valor de negocio. Define la arquitectura del sistema, asegura la alineación con los objetivos institucionales y participa activamente en el desarrollo backend, frontend y la implementación del módulo de cifrado.

- Scrum Master / Full Stack: Javier Eduardo Morán Jurado
  Responsabilidades: Facilita la correcta aplicación de la metodología Scrum, elimina impedimentos que afecten al equipo, coordina las ceremonias ágiles y garantiza el flujo de trabajo. Participa en el desarrollo full stack, con especial énfasis en la gestión de bases de datos y la integración de componentes.

- Developer / Full Stack: Nicolás Gutiérrez Escudero
  Responsabilidades: Se encarga del desarrollo frontend y backend, implementación de la aplicación móvil, diseño de interfaces de usuario, integración de APIs RESTful y pruebas de funcionamiento. Contribuye en todas las capas del sistema para garantizar una experiencia fluida.
