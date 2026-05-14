import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/event_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_dialog.dart';

class LugaresScreen extends StatefulWidget {
  const LugaresScreen({super.key});

  @override
  State<LugaresScreen> createState() => _LugaresScreenState();
}

class _LugaresScreenState extends State<LugaresScreen> {
  List<dynamic> _lugares = [];
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
      _lugares = await EventService.listPlaces();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForm({Map<String, dynamic>? lugar}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _LugarForm(
        lugar: lugar,
        onSave: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  Future<void> _confirmDelete(dynamic l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${l['nombre']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await EventService.deletePlace(l['id'].toString());
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lugar eliminado'), backgroundColor: AppTheme.secondaryColor));
      } catch (e) {
        if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Lugares', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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
                  Expanded(child: Text('Lugares (${_lugares.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo lugar'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  ),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))
                          : _lugares.isEmpty
                              ? const Center(child: Text('No hay lugares registrados.'))
                              : isWide ? _buildTable() : _buildList(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Card(elevation: 2, child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: const [
        DataColumn(label: Text('Nombre')), DataColumn(label: Text('Coordenadas')), DataColumn(label: Text('Acciones')),
      ], rows: _lugares.map((l) {
        return DataRow(cells: [
          DataCell(Text(l['nombre']?.toString() ?? '')),
          DataCell(Text(l['coordenadas']?.toString() ?? '—')),
          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, size: 20, color: AppTheme.primaryColor), onPressed: () => _showForm(lugar: l)),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(l)),
          ])),
        ]);
      }).toList()),
    ));
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _lugares.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, i) {
        final l = _lugares[i];
        return ListTile(
          title: Text(l['nombre']?.toString() ?? ''),
          subtitle: Text(l['coordenadas']?.toString() ?? 'Sin coordenadas'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, color: AppTheme.primaryColor), onPressed: () => _showForm(lugar: l)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(l)),
          ]),
        );
      },
    );
  }
}

class _LugarForm extends StatefulWidget {
  final Map<String, dynamic>? lugar;
  final VoidCallback onSave;
  const _LugarForm({this.lugar, required this.onSave});

  @override
  State<_LugarForm> createState() => _LugarFormState();
}

class _LugarFormState extends State<_LugarForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  bool _isLoading = false;
  bool _gettingGps = false;
  bool _gpsObtenido = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lugar;
    _nombreCtrl = TextEditingController(text: l?['nombre']?.toString() ?? '');
    if (l != null && l['coordenadas'] != null) {
      final parts = l['coordenadas'].toString().split(',');
      if (parts.length == 2) {
        _latCtrl = TextEditingController(text: parts[0].trim());
        _lngCtrl = TextEditingController(text: parts[1].trim());
      } else {
        _latCtrl = TextEditingController();
        _lngCtrl = TextEditingController();
      }
    } else {
      _latCtrl = TextEditingController();
      _lngCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerGps() async {
    setState(() => _gettingGps = true);
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) ErrorDialog.show(context, 'Activa la ubicación GPS en tu dispositivo.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (mounted) ErrorDialog.show(context, 'Permiso de ubicación denegado.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) ErrorDialog.show(context, 'Permiso de ubicación denegado permanentemente. Actívalo en configuración.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      _gpsObtenido = true;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ErrorDialog.show(context, 'Error obteniendo ubicación: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _gettingGps = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? coords;
    if (_latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty) {
      coords = '${_latCtrl.text.trim()},${_lngCtrl.text.trim()}';
    } else if (_gpsObtenido && _latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty) {
      coords = '${_latCtrl.text.trim()},${_lngCtrl.text.trim()}';
    }

    setState(() => _isLoading = true);
    try {
      if (widget.lugar != null) {
        await EventService.updatePlace(
          id: widget.lugar!['id'].toString(),
          nombre: _nombreCtrl.text.trim(),
          coordenadas: coords,
        );
      } else {
        await EventService.createPlace(
          nombre: _nombreCtrl.text.trim(),
          coordenadas: coords,
        );
      }
      widget.onSave();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.lugar != null ? 'Lugar actualizado' : 'Lugar creado'),
        backgroundColor: AppTheme.secondaryColor,
      ));
    } catch (e) {
      if (mounted) ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lugar != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(isEdit ? 'Editar lugar' : 'Nuevo lugar', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(label: 'Nombre del lugar', controller: _nombreCtrl, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: CustomTextField(label: 'Latitud', controller: _latCtrl, hintText: '4.123456', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(label: 'Longitud', controller: _lngCtrl, hintText: '-72.123456', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Text('O usa el GPS para obtener la ubicación actual', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _gettingGps ? null : _obtenerGps,
              icon: _gettingGps
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_gpsObtenido ? Icons.check_circle : Icons.my_location, color: _gpsObtenido ? AppTheme.secondaryColor : null),
              label: Text(_gettingGps ? 'Obteniendo ubicación...' : _gpsObtenido ? '¡Ubicación obtenida!' : 'Usar mi ubicación actual'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gpsObtenido ? AppTheme.secondaryColor : null,
                side: BorderSide(color: _gpsObtenido ? AppTheme.secondaryColor : Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(text: isEdit ? 'Guardar cambios' : 'Crear lugar', onPressed: _isLoading ? null : _save, isLoading: _isLoading),
          ]),
        ),
      ),
    );
  }
}
