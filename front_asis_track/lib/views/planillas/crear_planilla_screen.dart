import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../services/campo_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/campo_preview.dart';
import '../../widgets/campo_modal.dart';
import '../../widgets/error_dialog.dart';

class CrearPlanillaScreen extends StatefulWidget {
  final int? planillaId;
  const CrearPlanillaScreen({super.key, this.planillaId});

  @override
  State<CrearPlanillaScreen> createState() => _CrearPlanillaScreenState();
}

class _CrearPlanillaScreenState extends State<CrearPlanillaScreen> {
  // ── Eventos ──
  List<EventoPlanilla> _eventos = [];
  EventoPlanilla? _eventoSeleccionado;
  bool _cargandoEventos = true;

  // ── Planilla ──
  bool _creando = false;
  int? _planillaId;
  List<CampoPreviewModel> _campos = [];
  bool _cargandoCampos = false;

  // ── Edición ──
  bool get _isEditing => widget.planillaId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _cargarPlanillaExistente(widget.planillaId!);
    } else {
      _cargarEventos();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARGA DE DATOS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cargarEventos() async {
    try {
      final eventos = await PlanillaService.obtenerEventos();
      if (mounted) setState(() { _eventos = eventos; _cargandoEventos = false; });
    } catch (_) {
      if (mounted) setState(() => _cargandoEventos = false);
    }
  }

  Future<void> _cargarPlanillaExistente(int id) async {
    setState(() { _cargandoEventos = true; _cargandoCampos = true; });
    try {
      final planilla = await PlanillaService.obtenerPlanilla(id);
      final eventos = await PlanillaService.obtenerEventos();
      final campos = await CampoService.obtenerCampos(id);
      if (mounted) {
        setState(() {
          _planillaId = planilla.id;
          _eventos = eventos;
          _campos = campos;
          if (planilla.eventoId != null) {
            _eventoSeleccionado = eventos.where((e) => e.id == planilla.eventoId).firstOrNull;
          }
          _cargandoEventos = false;
          _cargandoCampos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _cargandoEventos = false; _cargandoCampos = false; });
        ErrorDialog.show(context, 'Error cargando planilla: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREAR PLANILLA BORRADOR
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _crearPlanilla() async {
    if (_eventoSeleccionado == null) {
      ErrorDialog.show(context, 'Selecciona un evento para continuar');
      return;
    }
    setState(() => _creando = true);
    try {
      final planilla = await PlanillaService.crearPlanilla({
        'eventoId': _eventoSeleccionado!.id,
        'origenId': 1,
      });
      if (mounted) setState(() { _planillaId = planilla.id; _creando = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _creando = false);
        ErrorDialog.show(context, 'Error al crear planilla: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMPOS: AGREGAR, EDITAR, ELIMINAR
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _agregarCampo() async {
    if (_planillaId == null) return;
    final result = await CampoModal.show(context, planillaId: _planillaId!);
    if (result != null && mounted) setState(() => _campos.add(result));
  }

  Future<void> _editarCampo(CampoPreviewModel campo) async {
    final result = await CampoModal.show(context, planillaId: _planillaId!, campoExistente: campo);
    if (result != null && mounted) {
      setState(() {
        final idx = _campos.indexWhere((c) => c.id == campo.id);
        if (idx >= 0) _campos[idx] = result;
      });
    }
  }

  Future<void> _eliminarCampo(CampoPreviewModel campo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Eliminar campo'),
          ],
        ),
        content: Text('¿Eliminar el campo "${campo.nombreCampo}"?', style: TextStyle(color: Colors.grey.shade700)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && campo.id != null) {
      try {
        await CampoService.eliminarCampo(campo.id!);
        if (mounted) {
          setState(() => _campos.removeWhere((c) => c.id == campo.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Campo eliminado'),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIRMAR / CANCELAR
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _confirmar() async {
    if (_campos.isEmpty) {
      ErrorDialog.show(context, 'Agrega al menos un campo antes de confirmar la planilla');
      return;
    }
    if (!mounted) return;
    // Actualizar la planilla con los datos finales
    try {
      if (_planillaId != null) {
        await PlanillaService.actualizarPlanilla(_planillaId!, {
          'origenId': 1,
          'eventoId': _eventoSeleccionado?.id,
        });
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(_isEditing ? 'Planilla actualizada exitosamente' : 'Planilla creada exitosamente'),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      context.pop();
    }
  }

  Future<void> _cancelar() async {
    if (_planillaId == null || _isEditing) {
      context.pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.warningColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Cancelar creación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de cancelar?\n\nSe eliminará la planilla y todos los campos que hayas agregado.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar y eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await PlanillaService.eliminarPlanilla(_planillaId!);
      } catch (_) {}
      if (mounted) context.pop();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _planillaId != null && !_isEditing ? _cancelar : () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Editar Planilla' : 'Nueva Planilla',
          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _cargandoEventos
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
                child: SingleChildScrollView(
                  padding: AppBreakpoints.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── PASO 1: Selección de evento ──
                      _buildStepHeader(
                        step: 1,
                        title: 'Seleccionar evento',
                        subtitle: 'Elige el evento al que pertenece esta planilla',
                        isCompleted: _planillaId != null,
                      ),
                      const SizedBox(height: 12),
                      _buildEventoSelector(),
                      const SizedBox(height: 24),

                      // ── Botón crear planilla (solo si no existe) ──
                      if (_planillaId == null && !_isEditing)
                        _buildCrearButton(),

                      // ── PASO 2: Campos ──
                      if (_planillaId != null) ...[
                        _buildStepHeader(
                          step: 2,
                          title: 'Campos de la planilla',
                          subtitle: 'Define la estructura de datos que tendrá la planilla',
                          isCompleted: _campos.isNotEmpty,
                        ),
                        const SizedBox(height: 12),
                        _buildCamposSection(),
                        const SizedBox(height: 32),

                        // ── Botones finales ──
                        _buildAcciones(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS COMPONENTES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStepHeader({
    required int step,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.secondaryColor : AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventoSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<EventoPlanilla>(
            value: _eventoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Evento',
              hintText: 'Selecciona un evento',
              prefixIcon: const Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _eventos.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.nombre, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: _planillaId != null ? null : (val) => setState(() => _eventoSeleccionado = val),
          ),
          if (_eventoSeleccionado?.descripcion != null && _eventoSeleccionado!.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _eventoSeleccionado!.descripcion!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrearButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _creando ? null : _crearPlanilla,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _creando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Crear planilla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCamposSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner de éxito ──
          if (!_isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Planilla creada. Agrega los campos que tendrá la planilla.',
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ── Header de campos con botón ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campos (${_campos.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gray900),
                  ),
                  if (_campos.isEmpty)
                    Text('Ningún campo agregado', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _agregarCampo,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar campo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Lista de campos ──
          if (_cargandoCampos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
              ),
            )
          else if (_campos.isEmpty)
            _buildEmptyFields()
          else
            ...List.generate(_campos.length, (i) {
              final c = _campos[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCampoCard(c, i),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyFields() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: Icon(Icons.playlist_add, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'Todavía no hay campos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            'Presiona "Agregar campo" para definir la\nestructura de tu planilla.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCard(CampoPreviewModel campo, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // ── Header del campo ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _miniActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () => _editarCampo(campo),
                    ),
                    const SizedBox(width: 4),
                    _miniActionBtn(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => _eliminarCampo(campo),
                    ),
                  ],
                ),
              ),
              // ── Preview del campo ──
              CampoPreview(campo: campo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildAcciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _confirmar,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              _isEditing ? 'Guardar cambios' : 'Confirmar planilla',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: TextButton.icon(
            onPressed: _cancelar,
            icon: Icon(
              _isEditing ? Icons.arrow_back : Icons.cancel_outlined,
              size: 18,
              color: _isEditing ? Colors.grey.shade600 : Colors.red,
            ),
            label: Text(
              _isEditing ? 'Volver al listado' : 'Cancelar creación',
              style: TextStyle(
                color: _isEditing ? Colors.grey.shade600 : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _isEditing ? Colors.grey.shade300 : Colors.red.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
