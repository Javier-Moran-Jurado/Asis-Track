import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/justificacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/justificacion_service.dart';
import '../../services/role_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/dynamic_info_card.dart';

class JustificacionesScreen extends StatefulWidget {
  const JustificacionesScreen({super.key});

  @override
  State<JustificacionesScreen> createState() => _JustificacionesScreenState();
}

class _JustificacionesScreenState extends State<JustificacionesScreen> {
  List<JustificacionModel> _justificaciones = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final isStudent = RoleService.isStudent(auth.currentUser?.rol ?? '');
      final codigo = int.tryParse(auth.currentUser?.codigo ?? '');
      if (isStudent && codigo != null) {
        context.read<StudentProvider>().cargarJustificaciones(codigo).catchError((e) {
          debugPrint('Error cargando justificaciones del estudiante: $e');
        });
      } else {
        _cargarJustificaciones().catchError((e) {
          debugPrint('Error cargando justificaciones: $e');
        });
      }
    });
  }

  Future<void> _cargarJustificaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final rol = auth.currentUser?.rol ?? '';
      final puedeValidar = RoleService.canValidateJustificacion(rol);

      List<JustificacionModel> data;
      if (puedeValidar) {
        // Admins / Decanos ven todas las justificaciones
        final raw = await JustificacionService.obtenerTodas();
        data = raw.map((e) => JustificacionModel.fromJson(e)).toList();
      } else {
        data = [];
      }

      if (mounted) {
        setState(() {
          _justificaciones = data;
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

  Future<void> _refrescar() async {
    final auth = context.read<AuthProvider>();
    final isStudent = RoleService.isStudent(auth.currentUser?.rol ?? '');
    final codigo = int.tryParse(auth.currentUser?.codigo ?? '');
    if (isStudent && codigo != null) {
      await context.read<StudentProvider>().refrescar(codigo);
    } else {
      await _cargarJustificaciones();
    }
  }

  List<JustificacionModel> _filtrar(List<JustificacionModel> lista) {
    if (_filtroEstado == 'TODOS') return lista;
    return lista
        .where((j) => j.estado.toUpperCase() == _filtroEstado)
        .toList();
  }

  Future<void> _aprobar(int id) async {
    final auth = context.read<AuthProvider>();
    final codigo = int.tryParse(auth.currentUser?.codigo ?? '') ?? 0;

    final observaciones = await _mostrarDialogoObservaciones('Aprobar justificación');
    if (observaciones == null) return;

    try {
      await JustificacionService.aprobarJustificacion(
        id: id,
        codigoDecano: codigo,
        observaciones: observaciones.isEmpty ? null : observaciones,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Justificación aprobada'),
              ],
            ),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _refrescar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _rechazar(int id) async {
    final auth = context.read<AuthProvider>();
    final codigo = int.tryParse(auth.currentUser?.codigo ?? '') ?? 0;

    final observaciones = await _mostrarDialogoObservaciones('Rechazar justificación');
    if (observaciones == null) return;

    try {
      await JustificacionService.rechazarJustificacion(
        id: id,
        codigoDecano: codigo,
        observaciones: observaciones.isEmpty ? null : observaciones,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Justificación rechazada'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _refrescar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _mostrarDialogoObservaciones(String titulo) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Observaciones (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalle(JustificacionModel justificacion) {
    final estado = justificacion.estado;
    final motivo = justificacion.motivo;
    final observaciones = justificacion.observaciones ?? '';
    final documentoUrl = justificacion.documentoUrl ?? '';
    final fechaSolicitud = justificacion.fechaSolicitud;
    final fechaRespuesta = justificacion.fechaRespuesta;
    final codigoEstudiante = justificacion.codigoEstudiante?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _obtenerColorEstado(estado).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_obtenerIconoEstado(estado),
                  color: _obtenerColorEstado(estado), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Justificación #${justificacion.id}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Estado', _obtenerEtiquetaEstado(estado)),
                _detailRow('Estudiante', 'Código: $codigoEstudiante'),
                _detailRow('Motivo', motivo),
                if (observaciones.isNotEmpty)
                  _detailRow('Observaciones', observaciones),
                if (documentoUrl.isNotEmpty)
                  _detailRow('Documento', documentoUrl),
                if (fechaSolicitud != null)
                  _detailRow('Fecha solicitud', _formatearFecha(fechaSolicitud)),
                if (fechaRespuesta != null)
                  _detailRow('Fecha revisión', _formatearFecha(fechaRespuesta)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.gray900)),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm', 'es').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<AuthProvider>().currentUser?.rol ?? '';
    final puedeValidar = RoleService.canValidateJustificacion(rol);
    final isStudent = RoleService.isStudent(rol);

    late final List<JustificacionModel> justificaciones;
    late final bool cargando;
    late final String? error;

    if (isStudent) {
      final prov = context.watch<StudentProvider>();
      justificaciones = prov.justificaciones;
      cargando = prov.isLoading;
      error = prov.errorMessage;
    } else {
      justificaciones = _justificaciones;
      cargando = _cargando;
      error = _error;
    }

    final filtradas = _filtrar(justificaciones);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Actualizar',
            onPressed: _refrescar,
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
                  // ── Encabezado ──
                  _buildHeader(justificaciones.length, puedeValidar),
                  const SizedBox(height: 16),
                  // ── Filtros ──
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  // ── Contenido ──
                  Expanded(
                    child: cargando
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                        : error != null
                            ? _buildError(error)
                            : filtradas.isEmpty
                                ? _buildEmpty()
                                : _buildList(filtradas, puedeValidar),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int count, bool puedeValidar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Justificaciones ($count)',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          puedeValidar
              ? 'Revisa y gestiona las solicitudes de justificación'
              : 'Consulta el estado de tus justificaciones',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    final filtros = [
      {'label': 'Todos', 'value': 'TODOS'},
      {'label': 'Pendientes', 'value': 'PENDIENTE'},
      {'label': 'Aprobadas', 'value': 'APROBADO'},
      {'label': 'Rechazadas', 'value': 'RECHAZADO'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((f) {
          final selected = _filtroEstado == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(f['label']!),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.gray900,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                setState(() => _filtroEstado = f['value']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError(String errorMsg) {
    return Center(
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
              child: const Icon(Icons.error_outline,
                  color: AppTheme.errorColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refrescar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            Text(
              _filtroEstado == 'TODOS'
                  ? 'No hay justificaciones registradas.'
                  : 'No hay justificaciones con estado "${_obtenerEtiquetaEstado(_filtroEstado)}".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<JustificacionModel> items, bool puedeValidar) {
    return RefreshIndicator(
      onRefresh: _refrescar,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildJustificacionCard(items[index], puedeValidar);
        },
      ),
    );
  }

  Widget _buildJustificacionCard(JustificacionModel item, bool puedeValidar) {
    final estado = item.estado;
    final motivo = item.motivo;
    final id = item.id;
    final codigoEstudiante = item.codigoEstudiante?.toString() ?? '';
    final observaciones = item.observaciones ?? '';
    final documentoUrl = item.documentoUrl ?? '';
    final fecha = item.fechaSolicitud;

    return DynamicInfoCard(
      title: 'Justificación #$id',
      topSubtitle: 'Estudiante: $codigoEstudiante',
      date: fecha,
      leadingIcon: _obtenerIconoEstado(estado),
      leadingIconColor: _obtenerColorEstado(estado),
      statusChips: [
        _obtenerStatusChip(estado),
      ],
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Motivo: $motivo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Obs: $observaciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (documentoUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    documentoUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actionButtons: [
        if (puedeValidar && estado.toUpperCase() == 'PENDIENTE') ...[
          OutlinedButton.icon(
            onPressed: () => _aprobar(id),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Aprobar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              side: const BorderSide(color: AppTheme.secondaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _rechazar(id),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
      onTap: () => _mostrarDetalle(item),
    );
  }

  StatusChipData _obtenerStatusChip(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return StatusChipData(
          text: 'Pendiente',
          color: const Color(0xFFB45309),
          backgroundColor: AppTheme.warningColor.withValues(alpha: 0.15),
        );
      case 'APROBADO':
        return StatusChipData(
          text: 'Aprobada',
          color: AppTheme.secondaryColor,
          backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
        );
      case 'RECHAZADO':
        return StatusChipData(
          text: 'Rechazada',
          color: AppTheme.errorColor,
          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.15),
        );
      default:
        return StatusChipData(
          text: estado,
          color: Colors.grey.shade700,
          backgroundColor: Colors.grey.shade100,
        );
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return AppTheme.warningColor;
      case 'APROBADO':
        return AppTheme.secondaryColor;
      case 'RECHAZADO':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Icons.hourglass_empty;
      case 'APROBADO':
        return Icons.check_circle_outline;
      case 'RECHAZADO':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _obtenerEtiquetaEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'APROBADO':
        return 'Aprobada';
      case 'RECHAZADO':
        return 'Rechazada';
      default:
        return estado;
    }
  }
}
