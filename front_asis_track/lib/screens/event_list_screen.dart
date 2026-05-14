import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/event_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_breakpoints.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> _eventos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await EventService.listEvents();
      if (mounted) setState(() => _eventos = data);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  void _seleccionar(dynamic e) {
    final id = e['id']?.toString() ?? '';
    final nombre = e['nombre']?.toString() ?? 'Evento';
    if (id.isEmpty) return;
    context.push('/planilla-digital/digitizar', extra: {
      'id': id,
      'nombre': nombre,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Planilla Digital',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _cargar,
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
                  Text(
                    'Selecciona un evento para digitalizar su planilla',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryColor),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.errorColor),
                                ),
                              )
                            : _eventos.isEmpty
                                ? const Center(child: Text('No hay eventos registrados.'))
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
            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Lugar', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Inicio', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Accion', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _eventos.map((e) {
            return DataRow(cells: [
              DataCell(Text(e['nombre']?.toString() ?? '')),
              DataCell(Text(_lugarName(e))),
              DataCell(Text(_fmt(e['fechaHoraInicio']))),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _seleccionar(e),
                  icon: const Icon(Icons.document_scanner_outlined, size: 16),
                  label: const Text('Digitalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _eventos.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final e = _eventos[i];
        return ListTile(
          title: Text(e['nombre']?.toString() ?? ''),
          subtitle: Text('${_lugarName(e)}  •  ${_fmt(e['fechaHoraInicio'])}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _seleccionar(e),
        );
      },
    );
  }
}
