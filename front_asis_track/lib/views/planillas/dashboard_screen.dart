import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  EstadisticasEvento? _estadisticas;
  bool _cargando = true;
  String? _error;
  final int _eventoId = 1;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final stats = await PlanillaService.obtenerEstadisticas(_eventoId);
      if (mounted) setState(() { _estadisticas = stats; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 16,
        title: const Text('Estadísticas',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: _cargando
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
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargarEstadisticas, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _estadisticas!;
    final isDesktop = AppBreakpoints.isDesktop(context);

    return SingleChildScrollView(
      padding: AppBreakpoints.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.nombreEvento != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(stats.nombreEvento!,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
            ),

          // ── Tarjetas resumen ──────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Total planillas', value: '${stats.totalPlanillas}', color: AppTheme.primaryColor, icon: Icons.assignment)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Total registros', value: '${stats.totalFilas}', color: AppTheme.secondaryColor, icon: Icons.table_rows)),
            ],
          ),
          const SizedBox(height: 32),

          // ── Gráficos por campo ────────────────────────────────────────
          if (stats.campos.isEmpty)
            const Center(child: Text('Sin datos de campos', style: TextStyle(color: Colors.grey)))
          else
            ...stats.campos.map((campo) => _buildCampoChart(campo, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildCampoChart(EstadisticasCampo campo, bool isDesktop) {
    final est = campo.estadisticas;
    if (est == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
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
            Text(campo.campo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
            const SizedBox(height: 4),
            Text('Tipo: ${campo.tipoCampo}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            if (campo.tipoCampo == 'numeric')
              _buildNumericChart(est, isDesktop)
            else if (est['frecuencias'] != null)
              _buildCategoricalCharts(
                  est['frecuencias'] as Map<String, dynamic>, isDesktop)
            else if (est['distribucion'] != null)
              _buildCategoricalCharts(
                  est['distribucion'] as Map<String, dynamic>, isDesktop)
            else
              const Text('Sin datos para graficar', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericChart(Map<String, dynamic> est, bool isDesktop) {
    final rangos = est['distribucionPorRango'] as List<dynamic>? ?? [];
    if (rangos.isEmpty) return const Text('Sin distribución', style: TextStyle(color: Colors.grey));

    final spots = <BarChartGroupData>[];
    final labels = <String>[];
    double maxY = 0;

    for (int i = 0; i < rangos.length; i++) {
      final r = rangos[i] as Map<String, dynamic>;
      final freq = (r['frecuencia'] as num).toDouble();
      if (freq > maxY) maxY = freq;
      labels.add(r['etiqueta']?.toString() ?? 'Rango ${i + 1}');
      spots.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: freq, color: AppTheme.primaryColor, width: isDesktop ? 20 : 12, borderRadius: BorderRadius.circular(4)),
      ]));
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: spots,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[idx], style: TextStyle(fontSize: isDesktop ? 11 : 9, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoricalCharts(Map<String, dynamic> frecuencias, bool isDesktop) {
    final entries = frecuencias.entries.toList();
    if (entries.isEmpty) return const Text('Sin frecuencias', style: TextStyle(color: Colors.grey));

    entries.sort((a, b) => (b.value as num).compareTo(a.value as num));
    final topEntries = entries.take(isDesktop ? 12 : 6).toList();

    final valorMasComun = frecuencias['valorMasComun'];

    return Column(
      children: [
        if (valorMasComun != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Valor más común: $valorMasComun',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),

        // ── Gráfica de pastel ──
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _buildPieSections(entries),
              centerSpaceRadius: isDesktop ? 50 : 35,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── Leyenda de la pastel ──
        if (isDesktop)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: entries.take(8).map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: _getPieColor(entries.indexOf(e)),
                    shape: BoxShape.circle,
                  )),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              );
            }).toList(),
          ),

        const SizedBox(height: 20),
        const Text('Distribución por valor',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        const SizedBox(height: 12),

        // ── Gráfica de barras ──
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: (topEntries.map((e) => (e.value as num).toDouble()).reduce(
                      (a, b) => a > b ? a : b) *
                  1.2),
              barGroups: _buildBarGroups(topEntries, isDesktop),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= topEntries.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(topEntries[idx].key,
                            style: TextStyle(fontSize: isDesktop ? 11 : 9, color: Colors.grey.shade600)),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, dynamic>> entries) {
    final total = entries.fold<double>(0, (sum, e) => sum + (e.value as num).toDouble());
    return entries.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      final pct = total > 0 ? ((e.value as num).toDouble() / total) * 100 : 0;
      return PieChartSectionData(
        color: _getPieColor(idx),
        value: (e.value as num).toDouble(),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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

  List<BarChartGroupData> _buildBarGroups(List<MapEntry<String, dynamic>> entries, bool isDesktop) {
    return entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: (e.value as num).toDouble(),
          color: AppTheme.secondaryColor,
          width: isDesktop ? 20 : 12,
          borderRadius: BorderRadius.circular(4)),
      ]);
    }).toList();
  }
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
