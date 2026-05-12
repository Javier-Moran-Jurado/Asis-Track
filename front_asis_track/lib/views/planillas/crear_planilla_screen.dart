import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';

class CrearPlanillaScreen extends StatefulWidget {
  const CrearPlanillaScreen({super.key});

  @override
  State<CrearPlanillaScreen> createState() => _CrearPlanillaScreenState();
}

class _CrearPlanillaScreenState extends State<CrearPlanillaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selector de evento
  List<EventoPlanilla> _eventos = [];
  EventoPlanilla? _eventoSeleccionado;
  bool _cargandoEventos = true;

  // Fila única
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();

  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    setState(() { _cargandoEventos = true; _error = null; });
    try {
      final eventos = await PlanillaService.obtenerEventos();
      if (mounted) setState(() { _eventos = eventos; _cargandoEventos = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargandoEventos = false;
      });
    }
  }

  Future<void> _crearPlanilla() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un evento'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() { _enviando = true; _error = null; });

    try {
      final payload = {
        'eventoId': _eventoSeleccionado!.id,
        'origen': 'DIGITAL',
        'filas': [
          {
            'cedula': _cedulaCtrl.text.trim(),
            'nombres': _nombresCtrl.text.trim(),
            'apellidos': _apellidosCtrl.text.trim(),
          }
        ],
      };

      await PlanillaService.crearPlanilla(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilla creada exitosamente'),
            backgroundColor: AppTheme.secondaryColor),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
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
        title: const Text('Nueva Planilla'),
        centerTitle: false,
      ),
      body: _cargandoEventos
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
                child: SingleChildScrollView(
                  padding: AppBreakpoints.responsivePadding(context),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // ── Evento ────────────────────────────────────────
                        const Text('Evento *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<EventoPlanilla>(
                          initialValue: _eventoSeleccionado,
                          decoration: const InputDecoration(hintText: 'Selecciona un evento'),
                          items: _eventos.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e.nombre));
                          }).toList(),
                          onChanged: (val) => setState(() => _eventoSeleccionado = val),
                          validator: (val) => val == null ? 'El evento es requerido' : null,
                        ),
                        const SizedBox(height: 20),
                        // ── Origen ───────────────────────────────────────
                        const Text('Origen',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text('Digital',
                              style: TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 20),
                        // ── Campos ───────────────────────────────────────
                        const Text('Datos del registro',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                        const SizedBox(height: 16),
                        _buildField('Cédula *', _cedulaCtrl, 'Ej: 1234567890',
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildField('Nombres *', _nombresCtrl, 'Ej: Juan Carlos'),
                        const SizedBox(height: 12),
                        _buildField('Apellidos *', _apellidosCtrl, 'Ej: Pérez Gómez'),
                        const SizedBox(height: 32),
                        // ── Error ────────────────────────────────────────
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                        CustomButton(
                          text: 'Crear planilla',
                          isPrimary: true,
                          isLoading: _enviando,
                          onPressed: _enviando ? null : _crearPlanilla,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Cancelar',
                          isPrimary: false,
                          isLoading: _enviando,
                          onPressed: _enviando ? null : () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
          validator: (val) => val == null || val.trim().isEmpty ? 'Este campo es requerido' : null,
        ),
      ],
    );
  }
}
