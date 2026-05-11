import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/historial_asistencia.dart';
import '../../providers/auth_provider.dart';
import '../../services/justificacion_service.dart';
import '../../services/role_service.dart';
import '../../themes/app_theme.dart';

class JustificacionesScreen extends StatefulWidget {
  const JustificacionesScreen({super.key});

  @override
  State<JustificacionesScreen> createState() => _JustificacionesScreenState();
}

class _JustificacionesScreenState extends State<JustificacionesScreen> {
  late List<HistorialAsistencia> _justificaciones;

  @override
  void initState() {
    super.initState();
    _justificaciones = [
      HistorialAsistencia(
        id: '2',
        fecha: DateTime.now().subtract(const Duration(days: 3)),
        materia: 'Base de Datos',
        tipoEvento: 'Práctica',
        asistio: false,
        estadoJustificacion: EstadoJustificacion.pendiente,
        motivoJustificacion: 'Cita médica con especialista',
        archivoAdjunto: 'orden_medica.pdf',
        docente: 'Lic. Carlos Ruiz',
        ubicacion: 'Aula 204 - Edificio A',
      ),
      HistorialAsistencia(
        id: '5',
        fecha: DateTime.now().subtract(const Duration(days: 8)),
        materia: 'Cálculo III',
        tipoEvento: 'Clase Teórica',
        asistio: false,
        estadoJustificacion: EstadoJustificacion.aprobada,
        motivoJustificacion: 'Calamidad doméstica',
        docente: 'Dr. Fernando Mejía',
        ubicacion: 'Aula 105 - Edificio B',
      ),
      HistorialAsistencia(
        id: '6',
        fecha: DateTime.now().subtract(const Duration(days: 15)),
        materia: 'Física II',
        tipoEvento: 'Laboratorio',
        asistio: false,
        estadoJustificacion: EstadoJustificacion.rechazada,
        motivoJustificacion: 'Problema de transporte',
        docente: 'Ing. Patricia Vega',
        ubicacion: 'Laboratorio 1 - Edificio C',
      ),
    ];
  }

  void _actualizarEstado(int index, EstadoJustificacion nuevoEstado) {
    setState(() {
      final item = _justificaciones[index];
      _justificaciones[index] = HistorialAsistencia(
        id: item.id,
        fecha: item.fecha,
        materia: item.materia,
        tipoEvento: item.tipoEvento,
        asistio: item.asistio,
        estadoJustificacion: nuevoEstado,
        motivoJustificacion: item.motivoJustificacion,
        archivoAdjunto: item.archivoAdjunto,
        docente: item.docente,
        ubicacion: item.ubicacion,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<AuthProvider>().currentUser?.rol ?? '';
    final puedeValidar = RoleService.canValidateJustificacion(rol);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Justificaciones',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _justificaciones.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 44,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sin justificaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No has enviado ninguna justificación todavía.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _justificaciones.length,
              itemBuilder: (context, index) {
                return _buildJustificacionCard(
                    _justificaciones[index], index, puedeValidar);
              },
            ),
    );
  }

  Widget _buildJustificacionCard(
      HistorialAsistencia item, int index, bool puedeValidar) {
    final fecha = DateFormat('d MMM yyyy', 'es').format(item.fecha);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/h-detalle', extra: item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                      color: _obtenerColorEstado(item.estadoJustificacion)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _obtenerIconoEstado(item.estadoJustificacion),
                      size: 22,
                      color: _obtenerColorEstado(item.estadoJustificacion),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.materia,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$fecha  •  ${item.docente}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(item.estadoJustificacion),
                ],
              ),
              if (item.motivoJustificacion != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motivo: ${item.motivoJustificacion!}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.archivoAdjunto != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      item.archivoAdjunto!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // ── Botones de validación (solo Decano / Administrador) ──
              if (puedeValidar &&
                  item.estadoJustificacion == EstadoJustificacion.pendiente) ...[
                const SizedBox(height: 16),
                _buildValidationButtons(index),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(EstadoJustificacion estado) {
    Color bgColor;
    Color textColor;
    String text;

    switch (estado) {
      case EstadoJustificacion.ninguna:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Sin justificar';
      case EstadoJustificacion.pendiente:
        bgColor = AppTheme.warningColor.withValues(alpha: 0.15);
        textColor = const Color(0xFFB45309);
        text = 'Pendiente';
      case EstadoJustificacion.aprobada:
        bgColor = AppTheme.secondaryColor.withValues(alpha: 0.15);
        textColor = AppTheme.secondaryColor;
        text = 'Aprobada';
      case EstadoJustificacion.rechazada:
        bgColor = AppTheme.errorColor.withValues(alpha: 0.15);
        textColor = AppTheme.errorColor;
        text = 'Rechazada';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildValidationButtons(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth > 300;
        final buttons = [
          OutlinedButton.icon(
            onPressed: () async {
              await JustificacionService.validarJustificacion(
                justificacionId: _justificaciones[index].id,
                aprobada: true,
              );
              if (mounted) {
                _actualizarEstado(index, EstadoJustificacion.aprobada);
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Aprobar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              side: const BorderSide(color: AppTheme.secondaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await JustificacionService.validarJustificacion(
                justificacionId: _justificaciones[index].id,
                aprobada: false,
              );
              if (mounted) {
                _actualizarEstado(index, EstadoJustificacion.rechazada);
              }
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ];

        if (useRow) {
          return Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 12),
              Expanded(child: buttons[1]),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(width: double.infinity, child: buttons[0]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: buttons[1]),
          ],
        );
      },
    );
  }

  Color _obtenerColorEstado(EstadoJustificacion estado) {
    switch (estado) {
      case EstadoJustificacion.ninguna:
        return Colors.grey;
      case EstadoJustificacion.pendiente:
        return AppTheme.warningColor;
      case EstadoJustificacion.aprobada:
        return AppTheme.secondaryColor;
      case EstadoJustificacion.rechazada:
        return AppTheme.errorColor;
    }
  }

  IconData _obtenerIconoEstado(EstadoJustificacion estado) {
    switch (estado) {
      case EstadoJustificacion.ninguna:
        return Icons.help_outline;
      case EstadoJustificacion.pendiente:
        return Icons.hourglass_empty;
      case EstadoJustificacion.aprobada:
        return Icons.check_circle_outline;
      case EstadoJustificacion.rechazada:
        return Icons.cancel_outlined;
    }
  }
}
