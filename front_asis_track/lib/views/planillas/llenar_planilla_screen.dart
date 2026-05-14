import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../services/campo_service.dart';
import '../../services/fila_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/error_dialog.dart';

class LlenarPlanillaScreen extends StatefulWidget {
  final int planillaId;
  const LlenarPlanillaScreen({super.key, required this.planillaId});

  @override
  State<LlenarPlanillaScreen> createState() => _LlenarPlanillaScreenState();
}

class _LlenarPlanillaScreenState extends State<LlenarPlanillaScreen> {
  Planilla? _planilla;
  List<CampoPreviewModel> _campos = [];
  List<Map<String, dynamic>> _filas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final results = await Future.wait([
        PlanillaService.obtenerPlanilla(widget.planillaId),
        CampoService.obtenerCampos(widget.planillaId),
        FilaService.obtenerFilas(widget.planillaId),
      ]);
      if (mounted) {
        setState(() {
          _planilla = results[0] as Planilla;
          _campos = results[1] as List<CampoPreviewModel>;
          _filas = results[2] as List<Map<String, dynamic>>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _cargando = false; });
    }
  }

  Future<void> _agregarFila() async {
    if (_campos.isEmpty) {
      ErrorDialog.show(context, 'Esta planilla no tiene campos configurados');
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilaFormModal(planillaId: widget.planillaId, campos: _campos, filaIndex: _filas.length),
    );
    if (result == true) _cargar();
  }

  Future<void> _editarFila(Map<String, dynamic> fila) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilaFormModal(planillaId: widget.planillaId, campos: _campos, filaExistente: fila, filaIndex: 0),
    );
    if (result == true) _cargar();
  }

  Future<void> _eliminarFila(Map<String, dynamic> fila) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar registro'),
        content: const Text('¿Eliminar este registro? No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await FilaService.eliminarFila(fila['id'] as int);
        if (mounted) {
          _cargar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Registro eliminado'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
        }
      } catch (e) {
        if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(
          _planilla?.nombreEvento ?? 'Llenar Planilla',
          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _cargar),
        ],
      ),
      floatingActionButton: !_cargando && _error == null
          ? FloatingActionButton.extended(
              onPressed: _agregarFila,
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo registro'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reintentar')),
    ]),
  ));

  Widget _buildContent() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: AppBreakpoints.responsivePadding(context),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header info
            _buildInfoHeader(),
            const SizedBox(height: 16),
            // Campos chip bar
            _buildCamposBar(),
            const SizedBox(height: 16),
            // Filas
            Expanded(child: _filas.isEmpty ? _buildEmpty() : _buildFilasTable()),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.assignment, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_planilla?.nombreEvento ?? 'Planilla #${widget.planillaId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
          const SizedBox(height: 4),
          Text('${_campos.length} campos  •  ${_filas.length} registros',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_filas.length}', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ]),
    );
  }

  Widget _buildCamposBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _campos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _campos[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(c.nombreCampo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              if (c.obligatorio) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
      ]),
      child: Icon(Icons.person_add_alt_1, size: 48, color: Colors.grey.shade400),
    ),
    const SizedBox(height: 16),
    Text('Sin registros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    const SizedBox(height: 6),
    Text('Presiona "Nuevo registro" para agregar datos', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
  ]));

  Widget _buildFilasTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
            columns: [
              const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w600))),
              ..._campos.map((c) => DataColumn(label: Text(c.nombreCampo, style: const TextStyle(fontWeight: FontWeight.w600)))),
              const DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
            rows: _filas.asMap().entries.map((entry) {
              final fila = entry.value;
              final datos = fila['datos'] as List<dynamic>? ?? [];
              return DataRow(cells: [
                DataCell(Text('${(fila['indice'] ?? entry.key + 1)}')),
                ..._campos.map((campo) {
                  final dato = datos.where((d) => d['campoId'] == campo.id).firstOrNull;
                  final valor = dato?['informacion']?.toString() ?? '';
                  
                  Widget cellContent;
                  if (valor.isEmpty) {
                    cellContent = const Text('—');
                  } else if (campo.tipoCampo.tipo == 'signature_file') {
                    cellContent = Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          valor,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        ),
                      ),
                    );
                  } else {
                    cellContent = Text(valor, overflow: TextOverflow.ellipsis);
                  }

                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: cellContent,
                    ),
                  );
                }),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  _actionBtn(Icons.edit_outlined, AppTheme.primaryColor, () => _editarFila(fila)),
                  const SizedBox(width: 4),
                  _actionBtn(Icons.delete_outline, Colors.red, () => _eliminarFila(fila)),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODAL DE FILA — Formulario interactivo para cada campo
// ═══════════════════════════════════════════════════════════════════════════════

class _FilaFormModal extends StatefulWidget {
  final int planillaId;
  final List<CampoPreviewModel> campos;
  final Map<String, dynamic>? filaExistente;
  final int filaIndex;

  const _FilaFormModal({required this.planillaId, required this.campos, this.filaExistente, required this.filaIndex});

  @override
  State<_FilaFormModal> createState() => _FilaFormModalState();
}

class _FilaFormModalState extends State<_FilaFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final Map<int, TextEditingController> _controllers;
  late final Map<int, String?> _selectedValues; // for combo/radio
  late final Map<int, Set<String>> _checkedValues; // for multivaluecheckbox
  late final Map<int, bool> _checkboxValues; // for checkbox
  late final Map<int, Uint8List?> _signatureBytes; // for signatures
  bool _guardando = false;

  bool get _isEditing => widget.filaExistente != null;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _selectedValues = {};
    _checkedValues = {};
    _checkboxValues = {};
    _signatureBytes = {};

    for (final campo in widget.campos) {
      final existingValue = _getExistingValue(campo.id!);
      switch (campo.tipoCampo.tipo) {
        case 'checkbox':
          _checkboxValues[campo.id!] = existingValue == 'true';
          break;
        case 'combo':
        case 'radio':
          _selectedValues[campo.id!] = existingValue;
          break;
        case 'multivaluecheckbox':
          _checkedValues[campo.id!] = existingValue != null && existingValue.isNotEmpty
              ? existingValue.split(',').map((s) => s.trim()).toSet()
              : {};
          break;
        case 'signature_file':
          _controllers[campo.id!] = TextEditingController(text: existingValue ?? '');
          _signatureBytes[campo.id!] = null;
          break;
        default:
          _controllers[campo.id!] = TextEditingController(text: existingValue ?? '');
      }
    }
  }

  String? _getExistingValue(int campoId) {
    if (widget.filaExistente == null) return null;
    final datos = widget.filaExistente!['datos'] as List<dynamic>? ?? [];
    final dato = datos.where((d) => d['campoId'] == campoId).firstOrNull;
    return dato?['informacion']?.toString();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final datos = <Map<String, dynamic>>[];
    for (final campo in widget.campos) {
      String informacion;
      switch (campo.tipoCampo.tipo) {
        case 'checkbox':
          informacion = (_checkboxValues[campo.id!] ?? false).toString();
          break;
        case 'combo':
        case 'radio':
          informacion = _selectedValues[campo.id!] ?? '';
          break;
        case 'multivaluecheckbox':
          informacion = (_checkedValues[campo.id!] ?? {}).join(', ');
          break;
        default:
          informacion = _controllers[campo.id!]?.text.trim() ?? '';
      }
      datos.add({'campoId': campo.id, 'posicion': 0, 'informacion': informacion});
    }

    try {
      int filaId;
      if (_isEditing) {
        filaId = widget.filaExistente!['id'] as int;
        await FilaService.actualizarFila(filaId, {
          'planillaId': widget.planillaId,
          'datos': datos,
        });
      } else {
        final res = await FilaService.crearFila({
          'planillaId': widget.planillaId,
          'datos': datos,
        });
        filaId = res['id'] as int;
      }

      for (final campo in widget.campos) {
        if (campo.tipoCampo.tipo == 'signature_file' && _signatureBytes[campo.id!] != null) {
          await FilaService.subirFirma(filaId, campo.id!, _signatureBytes[campo.id!]!);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(_isEditing ? Icons.edit : Icons.person_add, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEditing ? 'Editar registro' : 'Nuevo registro', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
                Text('Completa los campos de la planilla', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ])),
            ]),
          ),
          const Divider(),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ...widget.campos.map((campo) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildCampoInput(campo),
                  )),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'Guardar cambios' : 'Registrar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCampoInput(CampoPreviewModel campo) {
    final label = '${campo.nombreCampo}${campo.obligatorio ? ' *' : ''}';
    final nombreLower = campo.nombreCampo.toLowerCase();
    
    // Inferencia heurística: si el tipo es genérico pero el nombre indica otra cosa
    String tipoEfectivo = campo.tipoCampo.tipo;
    if (tipoEfectivo == 'text') {
      if (nombreLower.contains('cedul') || nombreLower.contains('cédul') || 
          nombreLower.contains('telef') || nombreLower.contains('teléf') || 
          nombreLower.contains('celular') || nombreLower.contains('edad')) {
        tipoEfectivo = 'numeric';
      } else if (nombreLower.contains('correo') || nombreLower.contains('email')) {
        tipoEfectivo = 'email';
      }
    }

    switch (tipoEfectivo) {
      case 'text':
      case 'email':
      case 'secret':
        return TextFormField(
          controller: _controllers[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(_iconFor(tipoEfectivo), size: 20, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          obscureText: tipoEfectivo == 'secret',
          keyboardType: tipoEfectivo == 'email' ? TextInputType.emailAddress : TextInputType.text,
          validator: (v) {
            if (campo.obligatorio && (v == null || v.trim().isEmpty)) return 'Campo obligatorio';
            if (tipoEfectivo == 'email' && v != null && v.trim().isNotEmpty) {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v.trim())) return 'Correo electrónico inválido';
            }
            return null;
          },
        );

      case 'numeric':
        return TextFormField(
          controller: _controllers[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.numbers, size: 20, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (campo.obligatorio && (v == null || v.trim().isEmpty)) return 'Campo obligatorio';
            if (v != null && v.trim().isNotEmpty) {
              if (int.tryParse(v.trim()) == null) return 'Debe ser un número válido';
              if (nombreLower.contains('cedul') || nombreLower.contains('cédul')) {
                if (v.trim().length < 5) return 'La cédula debe tener al menos 5 dígitos';
              }
            }
            return null;
          },
        );

      case 'date':
        return TextFormField(
          controller: _controllers[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'YYYY-MM-DD',
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _controllers[campo.id!]!.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
          validator: campo.obligatorio ? (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null : null,
        );

      case 'checkbox':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
          child: CheckboxListTile(
            title: Text(campo.nombreCampo, style: const TextStyle(fontSize: 14)),
            value: _checkboxValues[campo.id!] ?? false,
            onChanged: (val) => setState(() => _checkboxValues[campo.id!] = val ?? false),
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );

      case 'combo':
        return DropdownButtonFormField<String>(
          value: _selectedValues[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: campo.opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) => setState(() => _selectedValues[campo.id!] = val),
          validator: campo.obligatorio ? (v) => v == null || v.isEmpty ? 'Selecciona una opción' : null : null,
        );

      case 'radio':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: Column(children: campo.opciones.map((opt) => RadioListTile<String>(
              title: Text(opt, style: const TextStyle(fontSize: 14)),
              value: opt,
              groupValue: _selectedValues[campo.id!],
              onChanged: (val) => setState(() => _selectedValues[campo.id!] = val),
              activeColor: AppTheme.primaryColor,
              dense: true,
            )).toList()),
          ),
        ]);

      case 'multivaluecheckbox':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: Column(children: campo.opciones.map((opt) => CheckboxListTile(
              title: Text(opt, style: const TextStyle(fontSize: 14)),
              value: _checkedValues[campo.id!]?.contains(opt) ?? false,
              onChanged: (val) => setState(() {
                final set = _checkedValues[campo.id!] ?? {};
                if (val == true) { set.add(opt); } else { set.remove(opt); }
                _checkedValues[campo.id!] = set;
              }),
              activeColor: AppTheme.primaryColor,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            )).toList()),
          ),
        ]);

      case 'file':
        return TextFormField(
          controller: _controllers[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.attach_file, size: 20, color: AppTheme.primaryColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'URL de archivo',
          ),
        );

      case 'signature_file':
        final bytes = _signatureBytes[campo.id!];
        final url = _controllers[campo.id!]!.text;
        final hasBytes = bytes != null;
        final hasUrl = url.isNotEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        hasBytes || hasUrl ? Icons.check_circle : Icons.draw_outlined,
                        color: hasBytes || hasUrl ? Colors.green : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasBytes ? 'Nueva firma lista para guardar' : (hasUrl ? 'Firma guardada en servidor' : 'Sin firma'),
                          style: TextStyle(color: hasBytes || hasUrl ? AppTheme.gray900 : Colors.grey.shade500),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final newBytes = await showDialog<Uint8List?>(
                            context: context,
                            builder: (_) => const _SignatureDialog(),
                          );
                          if (newBytes != null) {
                            setState(() => _signatureBytes[campo.id!] = newBytes);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                        ),
                        child: Text(hasBytes || hasUrl ? 'Cambiar' : 'Añadir firma'),
                      ),
                    ],
                  ),
                  if (hasBytes || hasUrl) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasBytes 
                            ? Image.memory(bytes, fit: BoxFit.contain)
                            : Image.network(url, fit: BoxFit.contain,
                                errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      default:
        return TextFormField(
          controller: _controllers[campo.id!],
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: campo.obligatorio ? (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null : null,
        );
    }
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'text': return Icons.text_fields;
      case 'email': return Icons.email_outlined;
      case 'secret': return Icons.lock_outline;
      default: return Icons.text_fields;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODAL DE FIRMA — Para dibujar o subir imagen
// ═══════════════════════════════════════════════════════════════════════════════

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? _uploadedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _uploadedImage = bytes);
    }
  }

  Future<void> _guardar() async {
    Uint8List? bytes;
    if (_tabController.index == 0) {
      if (_signatureController.isNotEmpty) {
        bytes = await _signatureController.toPngBytes();
      }
    } else {
      bytes = _uploadedImage;
    }
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Firma Digital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.draw), text: 'Dibujar'),
                Tab(icon: Icon(Icons.image), text: 'Subir Imagen'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Dibujar
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _signatureController.clear(),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                  // Tab Subir
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadedImage != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: Image.memory(_uploadedImage!, fit: BoxFit.contain),
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(
                            child: Text('Ninguna imagen seleccionada', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Seleccionar Imagen'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: const Text('Guardar Firma'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
