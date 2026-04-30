import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/historial_asistencia.dart';
import '../../themes/app_theme.dart';

class HistorialDetalleScreen extends StatelessWidget {
  final HistorialAsistencia asistencia;

  const HistorialDetalleScreen({super.key, required this.asistencia});

  @override
  Widget build(BuildContext context) {
    final bool esFalta = !asistencia.asistio;
    final bool mostrarBotonJustificar = esFalta &&
        (asistencia.estadoJustificacion == EstadoJustificacion.ninguna ||
         asistencia.estadoJustificacion == EstadoJustificacion.rechazada);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Detalle de Asistencia'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card de Información General ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.class_outlined, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asistencia.materia,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              asistencia.tipoEvento,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: DateFormat('EEEE, d MMMM yyyy', 'es').format(asistencia.fecha),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Hora',
                    value: DateFormat('HH:mm').format(asistencia.fecha),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Docente a cargo',
                    value: asistencia.docente,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Ubicación',
                    value: asistencia.ubicacion,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estado de Asistencia',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: esFalta
                              ? AppTheme.errorColor.withValues(alpha: 0.1)
                              : AppTheme.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              esFalta ? Icons.close : Icons.check,
                              size: 16,
                              color: esFalta ? AppTheme.errorColor : AppTheme.secondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              esFalta ? 'Falta' : 'Presente',
                              style: TextStyle(
                                color: esFalta ? AppTheme.errorColor : AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Card de Justificación (si es falta y tiene justificación) ──
            if (esFalta && asistencia.estadoJustificacion != EstadoJustificacion.ninguna)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles de Justificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.info_outline,
                      label: 'Estado',
                      value: _obtenerTextoEstado(asistencia.estadoJustificacion),
                      valueColor: _obtenerColorEstado(asistencia.estadoJustificacion),
                    ),
                    if (asistencia.motivoJustificacion != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Motivo:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asistencia.motivoJustificacion!,
                        style: const TextStyle(fontSize: 15, color: AppTheme.gray900),
                      ),
                    ],
                    if (asistencia.archivoAdjunto != null) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          // TODO: Abrir archivo adjunto
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.05),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  asistencia.archivoAdjunto!,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.download_rounded, color: AppTheme.primaryColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (mostrarBotonJustificar) const SizedBox(height: 32),

            // ── Botón Justificar ──────────────────────────────────────────
            if (mostrarBotonJustificar)
              ElevatedButton.icon(
                onPressed: () {
                  // Acción desactivada por ahora
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Justificar Falta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _obtenerTextoEstado(EstadoJustificacion estado) {
    switch (estado) {
      case EstadoJustificacion.ninguna: return 'Sin justificar';
      case EstadoJustificacion.pendiente: return 'En revisión';
      case EstadoJustificacion.aprobada: return 'Aprobada';
      case EstadoJustificacion.rechazada: return 'Rechazada';
    }
  }

  Color _obtenerColorEstado(EstadoJustificacion estado) {
    switch (estado) {
      case EstadoJustificacion.ninguna: return Colors.grey;
      case EstadoJustificacion.pendiente: return const Color(0xFFB45309);
      case EstadoJustificacion.aprobada: return AppTheme.secondaryColor;
      case EstadoJustificacion.rechazada: return AppTheme.errorColor;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppTheme.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
