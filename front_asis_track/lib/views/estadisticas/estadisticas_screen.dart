import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../services/reporte_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  // ── Estado general ──
  bool _cargandoEventos = true;
  bool _cargandoStats = false;
  String? _error;

  // ── Datos ──
  List<EventoPlanilla> _eventos = [];
  EventoPlanilla? _eventoSeleccionado;
  Map<String, dynamic>? _resumenJustificaciones;
  EstadisticasEvento? _estadisticas;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargandoEventos = true; _error = null; });
    try {
      final futures = await Future.wait([
        PlanillaService.obtenerEventos(),
        ReporteService.resumenJustificaciones().catchError((_) => <String, dynamic>{}),
      ]);
      if (mounted) {
        setState(() {
          _eventos = futures[0] as List<EventoPlanilla>;
          _resumenJustificaciones = futures[1] as Map<String, dynamic>;
          _cargandoEventos = false;
          if (_eventos.isNotEmpty) {
            _eventoSeleccionado = _eventos.first;
            _cargarEstadisticasEvento(_eventoSeleccionado!.id);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargandoEventos = false;
      });
    }
  }

  Future<void> _cargarEstadisticasEvento(int eventoId) async {
    setState(() { _cargandoStats = true; });
    try {
      final stats = await PlanillaService.obtenerEstadisticas(eventoId);
      if (mounted) setState(() { _estadisticas = stats; _cargandoStats = false; });
    } catch (e) {
      if (mounted) setState(() {
        _estadisticas = null;
        _cargandoStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Estadísticas',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargandoEventos
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: AppBreakpoints.responsivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resumen de justificaciones ──
              if (_resumenJustificaciones != null && _resumenJustificaciones!.isNotEmpty)
                _buildResumenJustificaciones(),

              const SizedBox(height: 24),

              // ── Selector de evento ──
              _buildEventoSelector(),
              const SizedBox(height: 24),

              // ── Estadísticas del evento ──
              if (_cargandoStats)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                )
              else if (_estadisticas != null)
                _buildEstadisticasEvento()
              else
                _buildSinDatos(),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RESUMEN DE JUSTIFICACIONES
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildResumenJustificaciones() {
    final pendientes = (_resumenJustificaciones!['pendientes'] as num?)?.toInt() ?? 0;
    final aprobadas = (_resumenJustificaciones!['aprobadas'] as num?)?.toInt() ?? 0;
    final rechazadas = (_resumenJustificaciones!['rechazadas'] as num?)?.toInt() ?? 0;
    final total = (_resumenJustificaciones!['total'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen de justificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final cards = [
              _SummaryCard(title: 'Total', value: '$total', color: AppTheme.primaryColor, icon: Icons.list_alt),
              _SummaryCard(title: 'Pendientes', value: '$pendientes', color: AppTheme.warningColor, icon: Icons.hourglass_empty),
              _SummaryCard(title: 'Aprobadas', value: '$aprobadas', color: AppTheme.secondaryColor, icon: Icons.check_circle_outline),
              _SummaryCard(title: 'Rechazadas', value: '$rechazadas', color: AppTheme.errorColor, icon: Icons.cancel_outlined),
            ];

            if (isWide) {
              return Row(
                children: cards.map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                )).toList(),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards.map((c) => SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: c,
              )).toList(),
            );
          },
        ),

        // ── Mini gráfica de pastel ──
        if (total > 0) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 140, width: 140,
                  child: PieChart(PieChartData(
                    sections: [
                      if (pendientes > 0) PieChartSectionData(
                        value: pendientes.toDouble(), color: AppTheme.warningColor,
                        title: '$pendientes', radius: 45,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (aprobadas > 0) PieChartSectionData(
                        value: aprobadas.toDouble(), color: AppTheme.secondaryColor,
                        title: '$aprobadas', radius: 45,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (rechazadas > 0) PieChartSectionData(
                        value: rechazadas.toDouble(), color: AppTheme.errorColor,
                        title: '$rechazadas', radius: 45,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  )),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Pendientes', AppTheme.warningColor),
                    const SizedBox(height: 8),
                    _legendItem('Aprobadas', AppTheme.secondaryColor),
                    const SizedBox(height: 8),
                    _legendItem('Rechazadas', AppTheme.errorColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SELECTOR DE EVENTO
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildEventoSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estadísticas por evento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
          const SizedBox(height: 4),
          Text('Selecciona un evento para ver sus estadísticas detalladas',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<int>(
              isExpanded: true,
              underline: const SizedBox(),
              value: _eventoSeleccionado?.id,
              hint: const Text('Selecciona un evento'),
              items: _eventos.map((e) => DropdownMenuItem<int>(
                value: e.id,
                child: Text(e.nombre, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (id) {
                if (id != null) {
                  setState(() {
                    _eventoSeleccionado = _eventos.firstWhere((e) => e.id == id);
                  });
                  _cargarEstadisticasEvento(id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS DEL EVENTO
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildEstadisticasEvento() {
    final stats = _estadisticas!;
    final isDesktop = AppBreakpoints.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tarjetas resumen ──
        Row(
          children: [
            Expanded(child: _SummaryCard(
              title: 'Planillas', value: '${stats.totalPlanillas}',
              color: AppTheme.primaryColor, icon: Icons.assignment,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(
              title: 'Registros', value: '${stats.totalFilas}',
              color: AppTheme.secondaryColor, icon: Icons.table_rows,
            )),
          ],
        ),
        const SizedBox(height: 24),

        // ── Gráficos por campo ──
        if (stats.campos.isEmpty)
          _buildSinDatos()
        else
          ...stats.campos.map((c) => _buildCampoChart(c, isDesktop)),
      ],
    );
  }

  Widget _buildSinDatos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Sin datos estadísticos', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Este evento aún no tiene registros',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoChart(EstadisticasCampo campo, bool isDesktop) {
    final est = campo.estadisticas;
    if (est == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campo.campo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                      Text('Tipo: ${campo.tipoCampo}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (campo.tipoCampo == 'numeric')
              _buildNumericChart(est, isDesktop)
            else if (est['frecuencias'] != null)
              _buildCategoricalChart(est['frecuencias'] as Map<String, dynamic>, isDesktop)
            else if (est['distribucion'] != null)
              _buildCategoricalChart(est['distribucion'] as Map<String, dynamic>, isDesktop)
            else
              Text('Sin datos para graficar', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericChart(Map<String, dynamic> est, bool isDesktop) {
    final rangos = est['distribucionPorRango'] as List<dynamic>? ?? [];
    if (rangos.isEmpty) return Text('Sin distribución', style: TextStyle(color: Colors.grey.shade400));

    final spots = <BarChartGroupData>[];
    final labels = <String>[];
    double maxY = 0;
    for (int i = 0; i < rangos.length; i++) {
      final r = rangos[i] as Map<String, dynamic>;
      final freq = (r['frecuencia'] as num).toDouble();
      if (freq > maxY) maxY = freq;
      labels.add(r['etiqueta']?.toString() ?? '${i + 1}');
      spots.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: freq, color: AppTheme.primaryColor,
            width: isDesktop ? 20 : 12, borderRadius: BorderRadius.circular(4)),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats summary row ──
        _buildNumericSummary(est),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = labels.length * 140.0; // 140px per label
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth,
                height: 200,
                child: BarChart(BarChartData(
                  maxY: maxY * 1.2,
                  barGroups: spots,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: TextStyle(fontSize: isDesktop ? 10 : 8, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                )),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNumericSummary(Map<String, dynamic> est) {
    final min = est['min']?.toString() ?? '-';
    final max = est['max']?.toString() ?? '-';
    final promedio = est['promedio'] != null
        ? (est['promedio'] as num).toStringAsFixed(2) : '-';
    final count = est['count']?.toString() ?? '-';

    return Wrap(
      spacing: 16, runSpacing: 8,
      children: [
        _miniStat('Mín', min, AppTheme.primaryColor),
        _miniStat('Máx', max, AppTheme.errorColor),
        _miniStat('Promedio', promedio, AppTheme.secondaryColor),
        _miniStat('Total', count, Colors.grey.shade700),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildCategoricalChart(Map<String, dynamic> frecuencias, bool isDesktop) {
    final entries = frecuencias.entries.toList();
    if (entries.isEmpty) return Text('Sin frecuencias', style: TextStyle(color: Colors.grey.shade400));

    entries.sort((a, b) => (b.value as num).compareTo(a.value as num));
    final topEntries = entries.take(isDesktop ? 10 : 6).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(PieChartData(
            sections: _buildPieSections(entries),
            centerSpaceRadius: isDesktop ? 40 : 30,
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: entries.asMap().entries.map((entry) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: _getPieColor(entry.key), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${entry.value.key} (${entry.value.value})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = topEntries.length * 100.0; // 100px per label
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth,
                height: 180,
                child: BarChart(BarChartData(
                  maxY: (topEntries.map((e) => (e.value as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2),
                  barGroups: topEntries.asMap().entries.map((entry) {
                    return BarChartGroupData(x: entry.key, barRods: [
                      BarChartRodData(
                        toY: (entry.value.value as num).toDouble(),
                        color: AppTheme.secondaryColor,
                        width: isDesktop ? 20 : 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]);
                  }).toList(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= topEntries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            topEntries[idx].key,
                            style: TextStyle(fontSize: isDesktop ? 10 : 8, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                )),
              ),
            );
          },
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, dynamic>> entries) {
    final total = entries.fold<double>(0, (sum, e) => sum + (e.value as num).toDouble());
    return entries.asMap().entries.map((entry) {
      final pct = total > 0 ? ((entry.value.value as num).toDouble() / total) * 100 : 0;
      return PieChartSectionData(
        color: _getPieColor(entry.key), value: (entry.value.value as num).toDouble(),
        title: '${pct.toStringAsFixed(0)}%', radius: 45,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  static const List<Color> _pieColors = [
    Color(0xFF1D5BF0), Color(0xFF22A45D), Color(0xFFF59E0B),
    Color(0xFF8B5CF6), Color(0xFFE02424), Color(0xFF06B6D4),
    Color(0xFFEC4899), Color(0xFF84CC16), Color(0xFFF97316),
    Color(0xFF6366F1), Color(0xFF14B8A6), Color(0xFFA855F7),
  ];

  Color _getPieColor(int index) => _pieColors[index % _pieColors.length];
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
