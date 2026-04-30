import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/historial_asistencia.dart';
import '../../themes/app_theme.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  // Mock data para el prototipo
  late List<HistorialAsistencia> _historialCompleto;
  late List<HistorialAsistencia> _historialFiltrado;

  @override
  void initState() {
    super.initState();
    _historialCompleto = [
      HistorialAsistencia(
        id: '1',
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        materia: 'Ingeniería de Software II',
        tipoEvento: 'Clase Teórica',
        asistio: true,
        docente: 'Ing. María López',
        ubicacion: 'Laboratorio 3 - Edificio C',
      ),
      HistorialAsistencia(
        id: '2',
        fecha: DateTime.now().subtract(const Duration(days: 3)),
        materia: 'Base de Datos',
        tipoEvento: 'Práctica',
        asistio: false,
        estadoJustificacion: EstadoJustificacion.pendiente,
        motivoJustificacion: 'Cita médica',
        docente: 'Lic. Carlos Ruiz',
        ubicacion: 'Aula 204 - Edificio A',
      ),
      HistorialAsistencia(
        id: '3',
        fecha: DateTime.now().subtract(const Duration(days: 7)),
        materia: 'Redes y Comunicaciones',
        tipoEvento: 'Clase Teórica',
        asistio: false,
        estadoJustificacion: EstadoJustificacion.ninguna,
        docente: 'Ing. Roberto Gómez',
        ubicacion: 'Aula Virtual',
      ),
      HistorialAsistencia(
        id: '4',
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        materia: 'Inteligencia Artificial',
        tipoEvento: 'Examen',
        asistio: true,
        docente: 'Dra. Ana Torres',
        ubicacion: 'Auditorio Principal',
      ),
    ];
    _historialFiltrado = List.from(_historialCompleto);
  }

  void _filtrarPorFecha() {
    setState(() {
      if (_fechaDesde == null && _fechaHasta == null) {
        _historialFiltrado = List.from(_historialCompleto);
        return;
      }

      _historialFiltrado = _historialCompleto.where((item) {
        final date = DateTime(item.fecha.year, item.fecha.month, item.fecha.day);
        
        bool pasaFiltroDesde = true;
        if (_fechaDesde != null) {
          final desde = DateTime(_fechaDesde!.year, _fechaDesde!.month, _fechaDesde!.day);
          pasaFiltroDesde = date.isAtSameMomentAs(desde) || date.isAfter(desde);
        }

        bool pasaFiltroHasta = true;
        if (_fechaHasta != null) {
          final hasta = DateTime(_fechaHasta!.year, _fechaHasta!.month, _fechaHasta!.day);
          pasaFiltroHasta = date.isAtSameMomentAs(hasta) || date.isBefore(hasta);
        }

        return pasaFiltroDesde && pasaFiltroHasta;
      }).toList();
    });
  }

  Future<void> _seleccionarRango(BuildContext context) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: _fechaDesde != null && _fechaHasta != null
          ? DateTimeRange(start: _fechaDesde!, end: _fechaHasta!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.gray900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _fechaDesde = range.start;
        _fechaHasta = range.end;
      });
      _filtrarPorFecha();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
    _filtrarPorFecha();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Historial de Asistencias',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false, // Ocultar si está en main layout
      ),
      body: Column(
        children: [
          // ── Controles de Filtro ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarRango(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fechaDesde != null && _fechaHasta != null
                                  ? '${DateFormat('dd/MM/yy').format(_fechaDesde!)} - ${DateFormat('dd/MM/yy').format(_fechaHasta!)}'
                                  : 'Filtrar por fechas',
                              style: TextStyle(
                                color: _fechaDesde != null ? AppTheme.gray900 : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_fechaDesde != null || _fechaHasta != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    tooltip: 'Limpiar filtros',
                  ),
                ]
              ],
            ),
          ),

          // ── Lista de Registros ────────────────────────────────────────
          Expanded(
            child: _historialFiltrado.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron registros',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historialFiltrado.length,
                    itemBuilder: (context, index) {
                      final item = _historialFiltrado[index];
                      return _HistorialCard(
                        item: item,
                        onTap: () {
                          context.push('/h-detalle', extra: item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final HistorialAsistencia item;
  final VoidCallback onTap;

  const _HistorialCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determinar estilo según si asistió o no
    final bool esFalta = !item.asistio;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Fecha y Tipo de Evento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(item.fecha),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    item.tipoEvento,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Materia
              Text(
                item.materia,
                style: const TextStyle(
                  color: AppTheme.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Fila inferior: Estado de Asistencia y Badge de Justificación
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: esFalta
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esFalta ? Icons.close : Icons.check,
                          size: 14,
                          color: esFalta ? AppTheme.errorColor : AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          esFalta ? 'Falta' : 'Presente',
                          style: TextStyle(
                            color: esFalta ? AppTheme.errorColor : AppTheme.secondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (esFalta) ...[
                    const SizedBox(width: 8),
                    _JustificacionBadge(estado: item.estadoJustificacion),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JustificacionBadge extends StatelessWidget {
  final EstadoJustificacion estado;

  const _JustificacionBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (estado) {
      case EstadoJustificacion.ninguna:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Sin justificar';
        break;
      case EstadoJustificacion.pendiente:
        bgColor = AppTheme.warningColor.withValues(alpha: 0.15);
        textColor = const Color(0xFFB45309); // Darker amber
        text = 'Pendiente';
        break;
      case EstadoJustificacion.aprobada:
        bgColor = AppTheme.secondaryColor.withValues(alpha: 0.15);
        textColor = AppTheme.secondaryColor;
        text = 'Justificada';
        break;
      case EstadoJustificacion.rechazada:
        bgColor = AppTheme.errorColor.withValues(alpha: 0.15);
        textColor = AppTheme.errorColor;
        text = 'Rechazada';
        break;
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
}
