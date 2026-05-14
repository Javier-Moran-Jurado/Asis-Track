import 'package:flutter/material.dart';
import '../models/planilla.dart';
import '../services/campo_service.dart';
import '../themes/app_theme.dart';
import '../widgets/campo_preview.dart';
import 'error_dialog.dart';

/// Modal para agregar o editar un campo de una planilla.
///
/// Flujo:
/// 1. GET /tipos-campo para cargar tipos disponibles desde BD
/// 2. Usuario selecciona tipo → se muestra previsualización en tiempo real
/// 3. Ingresa nombre del campo (obligatorio)
/// 4. Si el tipo tiene opciones: agregar/eliminar opciones en el mismo modal
/// 5. Confirmar → POST/PUT a /campos
class CampoModal extends StatefulWidget {
  final int planillaId;
  final CampoPreviewModel? campoExistente;

  const CampoModal({super.key, required this.planillaId, this.campoExistente});

  static Future<CampoPreviewModel?> show(BuildContext context, {required int planillaId, CampoPreviewModel? campoExistente}) {
    return showModalBottomSheet<CampoPreviewModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CampoModal(planillaId: planillaId, campoExistente: campoExistente),
      ),
    );
  }

  @override
  State<CampoModal> createState() => _CampoModalState();
}

class _CampoModalState extends State<CampoModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  List<TipoCampoModel> _tipos = [];
  TipoCampoModel? _tipoSeleccionado;
  List<String> _opciones = [];
  final _opcionCtrl = TextEditingController();
  bool _cargandoTipos = true;
  bool _guardando = false;
  bool _obligatorio = true;

  bool get _isEditing => widget.campoExistente != null;

  @override
  void initState() {
    super.initState();
    final existente = widget.campoExistente;
    if (existente != null) {
      _nombreCtrl.text = existente.nombreCampo;
      _tipoSeleccionado = existente.tipoCampo;
      _opciones = List.from(existente.opciones);
      _obligatorio = existente.obligatorio;
    }
    _cargarTipos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _opcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await CampoService.obtenerTiposCampo();
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _cargandoTipos = false;
          // Si estamos editando, encontrar el tipo correcto en la lista cargada
          if (_isEditing && _tipoSeleccionado != null) {
            final match = tipos.where((t) => t.id == _tipoSeleccionado!.id).firstOrNull;
            if (match != null) _tipoSeleccionado = match;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoTipos = false);
    }
  }

  void _agregarOpcion() {
    final val = _opcionCtrl.text.trim();
    if (val.isNotEmpty && !_opciones.contains(val)) {
      setState(() {
        _opciones.add(val);
        _opcionCtrl.clear();
      });
    }
  }

  void _eliminarOpcion(int index) {
    setState(() => _opciones.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) {
      ErrorDialog.show(context, 'Selecciona un tipo de campo');
      return;
    }
    if (_tipoSeleccionado!.requiereOpciones && _opciones.isEmpty) {
      ErrorDialog.show(context, 'Agrega al menos una opción para este tipo de campo');
      return;
    }

    setState(() => _guardando = true);

    final campo = CampoPreviewModel(
      id: widget.campoExistente?.id,
      planillaId: widget.planillaId,
      nombreCampo: _nombreCtrl.text.trim(),
      obligatorio: _obligatorio,
      tipoCampo: _tipoSeleccionado!,
      opciones: _tipoSeleccionado!.requiereOpciones ? _opciones : [],
    );

    try {
      CampoPreviewModel result;
      if (_isEditing) {
        result = await CampoService.actualizarCampo(widget.campoExistente!.id!, campo);
      } else {
        result = await CampoService.crearCampo(campo);
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Título ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.add_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Editar campo' : 'Agregar campo',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900),
                      ),
                      Text(
                        _isEditing ? 'Modifica los datos del campo' : 'Define un nuevo campo para la planilla',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tipo de campo ──
              _buildSectionLabel('Tipo de campo', Icons.category_outlined),
              const SizedBox(height: 8),
              _cargandoTipos
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                      ),
                    )
                  : DropdownButtonFormField<TipoCampoModel>(
                      value: _tipoSeleccionado,
                      decoration: InputDecoration(
                        hintText: 'Selecciona un tipo',
                        prefixIcon: Icon(
                          _tipoSeleccionado != null ? _iconoTipo(_tipoSeleccionado!.tipo) : Icons.category_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _tipos.map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(_iconoTipo(t.tipo), size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 10),
                            Text(t.nombreEspanol),
                          ],
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() {
                        _tipoSeleccionado = val;
                        if (val != null && !val.requiereOpciones) _opciones = [];
                      }),
                      validator: (v) => v == null ? 'Selecciona un tipo' : null,
                    ),
              const SizedBox(height: 20),

              // ── Nombre del campo ──
              _buildSectionLabel('Nombre del campo', Icons.label_outline),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: Nombre completo, Fecha de nacimiento...',
                  prefixIcon: const Icon(Icons.text_fields, color: AppTheme.primaryColor, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ── Obligatorio ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  title: const Text('Campo obligatorio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _obligatorio ? 'El campo será requerido' : 'El campo será opcional',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  value: _obligatorio,
                  onChanged: (val) => setState(() => _obligatorio = val),
                  activeTrackColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              // ── Opciones (si aplica) ──
              if (_tipoSeleccionado != null && _tipoSeleccionado!.requiereOpciones) ...[
                _buildSectionLabel('Opciones', Icons.list_alt_outlined),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _opcionCtrl,
                        decoration: InputDecoration(
                          hintText: 'Escribe una opción...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _agregarOpcion(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _agregarOpcion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_opciones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Agrega al menos una opción',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: List.generate(_opciones.length, (i) => Chip(
                      label: Text(_opciones[i], style: const TextStyle(fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _eliminarOpcion(i),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                      deleteIconColor: Colors.grey.shade600,
                    )),
                  ),
                const SizedBox(height: 16),
              ],

              // ── Previsualización ──
              if (_tipoSeleccionado != null) ...[
                _buildSectionLabel('Previsualización', Icons.visibility_outlined),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CampoPreview(
                    campo: CampoPreviewModel(
                      planillaId: widget.planillaId,
                      nombreCampo: _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : 'Nombre del campo',
                      obligatorio: _obligatorio,
                      tipoCampo: _tipoSeleccionado!,
                      opciones: _tipoSeleccionado!.requiereOpciones ? _opciones : [],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Botones ──
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEditing ? Icons.save_outlined : Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Guardar cambios' : 'Confirmar campo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gray900),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
      ],
    );
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'text': return Icons.text_fields;
      case 'numeric': return Icons.numbers;
      case 'date': return Icons.calendar_today;
      case 'email': return Icons.email_outlined;
      case 'secret': return Icons.lock_outline;
      case 'checkbox': return Icons.check_box_outlined;
      case 'multivaluecheckbox': return Icons.checklist;
      case 'combo': return Icons.arrow_drop_down_circle_outlined;
      case 'radio': return Icons.radio_button_checked;
      case 'signature_file': return Icons.draw_outlined;
      case 'file': return Icons.attach_file;
      default: return Icons.help_outline;
    }
  }
}

class CustomField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomField({super.key, required this.label, required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    );
  }
}
