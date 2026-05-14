import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/dynamic_info_card.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  List<dynamic> _eventos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await EventService.listEvents();
      setState(() => _eventos = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _lugarName(dynamic e) {
    if (e['lugar'] is Map) return e['lugar']['nombre']?.toString() ?? '';
    return '';
  }

  String _fmt(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return iso.toString();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showForm({Map<String, dynamic>? evento}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EventoForm(
        evento: evento,
        onSave: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  Future<void> _confirmDelete(dynamic ev) async {
    final planillas = ev['planillas'];
    final tienePlanillas = planillas != null && planillas is List && planillas.isNotEmpty;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Eliminar "${ev['nombre']}"?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (tienePlanillas)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Este evento tiene ${planillas.length} planilla${planillas.length == 1 ? '' : 's'} asociada${planillas.length == 1 ? '' : 's'}. No se puede eliminar hasta que se eliminen primero.',
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                )),
              ]),
            )
          else
            const Text('No hay planillas asociadas a este evento.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cerrar')),
          if (!tienePlanillas)
            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await EventService.deleteEvent(ev['id'].toString());
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento eliminado'), backgroundColor: AppTheme.secondaryColor));
      } catch (e) {
        if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Eventos', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryColor), onPressed: _load)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: AppBreakpoints.responsivePadding(context),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text('Eventos (${_eventos.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo evento'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  ),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))
                          : _eventos.isEmpty
                              ? const Center(child: Text('No hay eventos registrados.'))
                               : _buildList(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildList() {
    return ListView.builder(
      itemCount: _eventos.length,
      padding: EdgeInsets.zero,
      itemBuilder: (ctx, i) {
        final e = _eventos[i];
        final startDt = DateTime.tryParse(e['fechaHoraInicio']?.toString() ?? '');
        
        return DynamicInfoCard(
          title: e['nombre']?.toString() ?? 'Sin nombre',
          topSubtitle: _lugarName(e),
          date: startDt,
          leadingIcon: Icons.calendar_today_outlined,
          leadingIconColor: AppTheme.primaryColor,
          extraContent: e['descripcion'] != null && e['descripcion'].toString().isNotEmpty
              ? Text(
                  e['descripcion'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                )
              : null,
          actionButtons: [
            OutlinedButton.icon(
              onPressed: () => _showForm(evento: e),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(e),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _EventoForm extends StatefulWidget {
  final Map<String, dynamic>? evento;
  final VoidCallback onSave;
  const _EventoForm({this.evento, required this.onSave});

  @override
  State<_EventoForm> createState() => _EventoFormState();
}

class _EventoFormState extends State<_EventoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String? _lugarId;
  List<dynamic> _lugares = [];
  bool _loadingPlaces = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final ev = widget.evento;
    _nombreCtrl = TextEditingController(text: ev?['nombre']?.toString() ?? '');
    _descCtrl = TextEditingController(text: ev?['descripcion']?.toString() ?? '');

    if (ev != null) {
      final start = DateTime.tryParse(ev['fechaHoraInicio']?.toString() ?? '');
      final end = DateTime.tryParse(ev['fechaHoraFin']?.toString() ?? '');
      if (start != null) {
        _fecha = start;
        _horaInicio = TimeOfDay.fromDateTime(start);
      }
      if (end != null) {
        _horaFin = TimeOfDay.fromDateTime(end);
      }
      if (ev['lugar'] is Map) _lugarId = ev['lugar']['id']?.toString();
    }

    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final data = await EventService.listPlaces();
      setState(() { _lugares = data; _loadingPlaces = false; });
    } catch (_) {
      setState(() => _loadingPlaces = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickTime({required bool isInicio}) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? (_horaInicio ?? now) : (_horaFin ?? now),
      helpText: isInicio ? 'Seleccionar hora inicio' : 'Seleccionar hora fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      setState(() {
        if (isInicio) _horaInicio = picked;
        else _horaFin = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lugarId == null) { ErrorDialog.show(context, 'Selecciona un lugar'); return; }
    if (_fecha == null) { ErrorDialog.show(context, 'Selecciona la fecha'); return; }
    if (_horaInicio == null) { ErrorDialog.show(context, 'Selecciona la hora de inicio'); return; }
    if (_horaFin == null) { ErrorDialog.show(context, 'Selecciona la hora de fin'); return; }

    final isEdit = widget.evento != null;
    final codigoUsuario = widget.evento?['codigoUsuario']?.toString() ?? '';
    final inicio = DateTime(_fecha!.year, _fecha!.month, _fecha!.day, _horaInicio!.hour, _horaInicio!.minute);
    final fin = DateTime(_fecha!.year, _fecha!.month, _fecha!.day, _horaFin!.hour, _horaFin!.minute);

    setState(() => _isLoading = true);
    try {
      if (isEdit) {
        await EventService.updateEvent(
          id: widget.evento!['id'].toString(),
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          lugarId: _lugarId!,
          codigoUsuario: codigoUsuario,
          fechaHoraInicio: inicio.toIso8601String(),
          fechaHoraFin: fin.toIso8601String(),
        );
      } else {
        await EventService.createEvent(
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          lugarId: _lugarId!,
          codigoUsuario: codigoUsuario,
          fechaHoraInicio: inicio.toIso8601String(),
          fechaHoraFin: fin.toIso8601String(),
        );
      }
      widget.onSave();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Evento actualizado' : 'Evento creado'), backgroundColor: AppTheme.secondaryColor));
    } catch (e) {
      if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _pickerButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(hasValue ? Icons.check_circle : Icons.calendar_today, size: 18, color: hasValue ? AppTheme.secondaryColor : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
              ]),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Seleccionar fecha';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Seleccionar hora';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.evento != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(isEdit ? 'Editar evento' : 'Nuevo evento', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(label: 'Nombre del evento', controller: _nombreCtrl, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            CustomTextField(label: 'Descripción (opcional)', controller: _descCtrl, maxLines: 3),
            const SizedBox(height: 12),
            _loadingPlaces
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : DropdownButtonFormField<String>(
                    value: _lugarId,
                    decoration: InputDecoration(labelText: 'Lugar', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    hint: const Text('Selecciona un lugar'),
                    items: _lugares.map((l) => DropdownMenuItem(value: l['id'].toString(), child: Text(l['nombre']?.toString() ?? ''))).toList(),
                    onChanged: (v) => setState(() => _lugarId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
            const SizedBox(height: 12),
            _pickerButton(label: 'Fecha', value: _fmtDate(_fecha), hasValue: _fecha != null, onTap: _pickDate),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _pickerButton(label: 'Hora inicio', value: _fmtTime(_horaInicio), hasValue: _horaInicio != null, onTap: () => _pickTime(isInicio: true))),
              const SizedBox(width: 12),
              Expanded(child: _pickerButton(label: 'Hora fin', value: _fmtTime(_horaFin), hasValue: _horaFin != null, onTap: () => _pickTime(isInicio: false))),
            ]),
            const SizedBox(height: 24),
            CustomButton(text: isEdit ? 'Guardar cambios' : 'Crear evento', onPressed: _isLoading ? null : _save, isLoading: _isLoading),
          ]),
        ),
      ),
    );
  }
}
