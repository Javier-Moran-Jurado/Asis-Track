import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/historial_asistencia.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/dynamic_info_card.dart';
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
                    padding: AppBreakpoints.responsivePadding(context),
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
    final bool esFalta = !item.asistio;

    List<StatusChipData> chips = [
      StatusChipData(
        text: esFalta ? 'Falta' : 'Presente',
        color: esFalta ? AppTheme.errorColor : AppTheme.secondaryColor,
        icon: esFalta ? Icons.close : Icons.check,
      ),
    ];

    if (esFalta) {
      chips.add(_obtenerChipJustificacion(item.estadoJustificacion));
    }

    return DynamicInfoCard(
      title: item.materia,
      topSubtitle: item.tipoEvento,
      date: item.fecha,
      statusChips: chips,
      onTap: onTap,
    );
  }

  StatusChipData _obtenerChipJustificacion(EstadoJustificacion estado) {
    switch (estado) {
      case EstadoJustificacion.ninguna:
        return StatusChipData(
          text: 'Sin justificar',
          color: Colors.grey.shade700,
          backgroundColor: Colors.grey.shade100,
        );
      case EstadoJustificacion.pendiente:
        return StatusChipData(
          text: 'Pendiente',
          color: const Color(0xFFB45309),
          backgroundColor: AppTheme.warningColor.withValues(alpha: 0.15),
        );
      case EstadoJustificacion.aprobada:
        return StatusChipData(
          text: 'Justificada',
          color: AppTheme.secondaryColor,
          backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
        );
      case EstadoJustificacion.rechazada:
        return StatusChipData(
          text: 'Rechazada',
          color: AppTheme.errorColor,
          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.15),
        );
    }
  }
}

