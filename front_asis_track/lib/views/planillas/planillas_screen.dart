import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/error_dialog.dart';

class PlanillasScreen extends StatefulWidget {
  const PlanillasScreen({super.key});

  @override
  State<PlanillasScreen> createState() => _PlanillasScreenState();
}

class _PlanillasScreenState extends State<PlanillasScreen> {
  List<Planilla> _planillas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPlanillas();
  }

  Future<void> _cargarPlanillas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final planillas = await PlanillaService.obtenerPlanillas();
      if (mounted) {
        setState(() {
          _planillas = planillas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _cargando = false;
        });
      }
    }
  }

  Future<void> _eliminar(Planilla p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Eliminar planilla'),
          ],
        ),
        content: Text(
          '¿Eliminar "${p.nombreEvento ?? 'Planilla #${p.id}'}"?\n\nEsta acción eliminará la planilla y todos sus campos. No se puede deshacer.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && p.id != null) {
      try {
        await PlanillaService.eliminarPlanilla(p.id!);
        if (mounted) {
          _cargarPlanillas();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Planilla eliminada correctamente'),
                ],
              ),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _mostrarCompartirModal(Planilla p) {
    // Generar la URL pública basada en la ubicación actual del navegador/app
    final baseUrl = Uri.base.origin;
    final url = '$baseUrl/#/formulario/${p.id}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir Formulario', textAlign: TextAlign.center),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escanea este código QR para acceder:'),
              const SizedBox(height: 20),
              Container(
                width: 232,
                height: 232,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 20),
            const Text('O copia el enlace directamente:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enlace copiado al portapapeles')),
                      );
                    },
                    tooltip: 'Copiar enlace',
                  )
                ],
              ),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/formulario/${p.id}');
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir aquí'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Planillas', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Actualizar',
            onPressed: _cargarPlanillas,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: AppBreakpoints.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header con botón de crear ──
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // ── Contenido ──
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                        : _error != null
                            ? _buildError()
                            : _planillas.isEmpty
                                ? _buildEmpty()
                                : isWide
                                    ? _buildTable()
                                    : _buildList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planillas (${_planillas.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestiona las planillas de asistencia de tus eventos',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/planilla-digital/eventos'),
              icon: const Icon(Icons.document_scanner_outlined, size: 18),
              label: const Text('Digitalizar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/planillas/nueva');
                _cargarPlanillas();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva planilla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
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
                onPressed: _cargarPlanillas,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined, size: 44, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 20),
              const Text('Sin planillas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
              const SizedBox(height: 8),
              Text(
                'No has creado ninguna planilla todavía.\nPresiona "Nueva planilla" para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/planillas/nueva');
                  _cargarPlanillas();
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear planilla'),
              ),
            ],
          ),
        ),
      );

  Widget _buildTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
          columns: const [
            DataColumn(label: Text('Evento', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Origen', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Campos', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Registros', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _planillas.map((p) {
            return DataRow(cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment, color: AppTheme.primaryColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(p.nombreEvento ?? 'Planilla #${p.id}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              DataCell(_buildOrigenChip(p.origen)),
              DataCell(Text('${p.totalCampos ?? 0}')),
              DataCell(Text('${p.totalFilas ?? 0}')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppTheme.primaryColor,
                      tooltip: 'Editar',
                      onPressed: () async {
                        await context.push('/planillas/nueva', extra: p.id);
                        _cargarPlanillas();
                      },
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      icon: Icons.share_outlined,
                      color: Colors.green,
                      tooltip: 'Compartir Formulario',
                      onPressed: () => _mostrarCompartirModal(p),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      icon: Icons.list_alt,
                      color: AppTheme.secondaryColor,
                      tooltip: 'Llenar planilla',
                      onPressed: () => context.push('/planillas/llenar', extra: p.id),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminar(p),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _cargarPlanillas,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _planillas.length,
        itemBuilder: (_, i) => _buildCard(_planillas[i]),
      ),
    );
  }

  Widget _buildCard(Planilla p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                  child: const Icon(Icons.assignment, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombreEvento ?? 'Planilla #${p.id}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gray900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildOrigenChip(p.origen),
                          const SizedBox(width: 8),
                          Text(
                            '${p.totalCampos ?? 0} campos  •  ${p.totalFilas ?? 0} registros',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/planillas/nueva', extra: p.id);
                    _cargarPlanillas();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/planillas/llenar', extra: p.id),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Llenar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _mostrarCompartirModal(p),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Compartir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _eliminar(p),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrigenChip(String? origen) {
    final isDigital = origen == null || origen.toLowerCase() == 'digital';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDigital
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        origen ?? 'Digital',
        style: TextStyle(
          color: isDigital ? AppTheme.primaryColor : AppTheme.warningColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
