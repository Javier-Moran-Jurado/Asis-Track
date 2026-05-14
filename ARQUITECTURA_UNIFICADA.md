# Arquitectura Unificada - Asis-Track

## Objetivo
Unificar `planilla`, `asistencia` y `justificacion` en `MicroservicioPlanilla`, eliminar `MicroservicioReporte` y generar reportes a partir de datos vivos de base de datos.

## Microservicios resultantes
- `MicroservicioPlanilla` (núcleo funcional): planillas, asistencias, justificaciones, reportes calculados.
- `MicroservicioUsuario` (autenticación/usuarios).
- `MicroServicioSeguridad` (llaves y seguridad transversal).

## Microservicios retirados
- `MicroservicioReporte`.
- `MicroservicioAsistencia` (su lógica se mueve a planilla).
- `MicroServicioJustificacion` (su lógica se mueve a planilla).

## Estructura propuesta en `MicroservicioPlanilla`

```text
MicroservicioPlanilla/
  src/main/java/co/edu/uceva/microservicioplanilla/
    auth/
      config/
      repository/
      service/
    domain/
      converters/
      model/
        Planilla.java
        Asistencia.java
        Justificacion.java
      repository/
        IPlanillaRepository.java
        IAsistenciaRepository.java
        IJustificacionRepository.java
      service/
        IPlanillaService.java
        IAsistenciaService.java
        IJustificacionService.java
        IReporteQueryService.java
        impl/
          PlanillaServiceImpl.java
          AsistenciaServiceImpl.java
          JustificacionServiceImpl.java
          ReporteQueryServiceImpl.java
    delibery/rest/
      PlanillaRestController.java
      AsistenciaRestController.java
      JustificacionRestController.java
      ReporteQueryRestController.java
    infrastructure/config/
      DataSeeder.java
```

## Modelos de datos unificados

### Planilla
- `id: Long`
- `fechaHoraInicio: LocalDateTime`
- `fechaHoraFin: LocalDateTime`
- `lugar: String` (cifrado según converter actual)
- `metadatos: String` (se conserva por compatibilidad funcional)
- `estructuraMetadata: String` (NUEVO, JSON de estructura de encabezados)
- `fechaCreacion: LocalDateTime`

Ejemplo de `estructuraMetadata`:

```json
{
  "encabezados": [
    { "nombre": "Cédula", "tipo_campo": "numerico", "opciones": [] },
    { "nombre": "Nombres", "tipo_campo": "texto", "opciones": [] },
    { "nombre": "Apellidos", "tipo_campo": "texto", "opciones": [] },
    { "nombre": "Firma", "tipo_campo": "firma", "opciones": [] }
  ]
}
```

### Asistencia
- `id: Long`
- `codigoEstudiante: String`
- `planillaId: Long`
- `fechaHoraRegistro: LocalDateTime`
- `estado: String` (`PRESENTE`, `AUSENTE`, `TARDANZA`, `SALIDA`, `JUSTIFICADO`)
- `geolocalizacion: String` (JSON serializado)
- `datosAdicionales: String` (JSON serializado)

### Justificacion
- `id: Long`
- `registroId: Long` (referencia al id de asistencia)
- `motivo: String`
- `documentoUrl: String`
- `estado: String` (`PENDIENTE`, `APROBADO`, `RECHAZADO`)
- `usuarioCodigo: String`
- `fechaSolicitud: LocalDateTime`
- `fechaRevision: LocalDateTime`
- `revisadoPor: String`
- `observaciones: String`

## Contratos API unificados

Base sugerida:
- `/api/v1/planilla-service/planillas/**`
- `/api/v1/planilla-service/asistencias/**`
- `/api/v1/planilla-service/justificaciones/**`
- `/api/v1/planilla-service/reportes/**`

Nota: La migración de APIs será directa (sin mantener rutas antiguas).

## Reportes sin tabla `Reporte`
- No se persiste entidad `Reporte`.
- Los endpoints de reportes ejecutan consultas agregadas sobre:
  - `planillas`
  - `asistencias`
  - `justificaciones`
- Salidas típicas:
  - asistencia por planilla
  - ausentismo por rango de fechas
  - justificaciones pendientes/aprobadas/rechazadas
  - trazabilidad por estudiante

## Cambios de infraestructura
- Eliminar servicios de `compose.yml`:
  - `reporte-service`
  - `asistenciaservice`
  - `justificacion-service`
- Mantener:
  - `planilla-service`
  - `usuarioservice`
  - `seguridad-service`
  - `db`
  - `redis`

## Orden recomendado de implementación
1. Extender `Planilla` con `estructuraMetadata`.
2. Mover modelos/repositorios/servicios de asistencia a `MicroservicioPlanilla`.
3. Mover modelos/repositorios/servicios de justificación a `MicroservicioPlanilla`.
4. Crear endpoints de reportes calculados y retirar dependencia de entidad `Reporte`.
5. Actualizar `compose.yml`, scripts y documentación.
6. Ejecutar pruebas funcionales de punta a punta.

