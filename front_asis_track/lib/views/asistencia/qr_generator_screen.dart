import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/evento_qr.dart';
import '../../models/zona.dart';
import '../../services/asistencia_service.dart';
import '../../widgets/custom_button.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();

  // State for zones
  List<Zona> _zonas = [];
  Zona? _zonaSeleccionada;
  bool _cargandoZonas = true;
  String? _errorZonas;

  // State for event creation
  bool _creandoEvento = false;
  EventoQr? _evento;
  bool _modoDemo = false;
  bool _verificandoUbicacion = false;
  String? _errorCreacion;

  // Nuevos campos
  String? _tipoSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  static const List<String> _tiposEvento = [
    'Clase',
    'Taller',
    'Préstamo',
    'Otro',
  ];

  // Controllers
  final _materiaCtrl = TextEditingController(text: 'Clase de Programación');
  final _actividadCtrl = TextEditingController(text: 'Asistencia Diaria');
  final _lugarCtrl = TextEditingController(text: 'Aula 402');

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  @override
  void dispose() {
    _materiaCtrl.dispose();
    _actividadCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarZonas() async {
    setState(() {
      _cargandoZonas = true;
      _errorZonas = null;
      _modoDemo = false;
    });
    try {
      final zonas = await AsistenciaService.fetchZonas();
      if (mounted) {
        setState(() {
          _zonas = zonas;
          _cargandoZonas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // En lugar de mostrar error, cargamos zonas de prueba para demostración
        setState(() {
          _modoDemo = true;
          _zonas = const [
            Zona(
                id: 'demo1',
                nombre: 'Auditorio Principal',
                latitud: 4.6097,
                longitud: -74.0817),
            Zona(
                id: 'demo2',
                nombre: 'Biblioteca Central',
                latitud: 4.6098,
                longitud: -74.0818),
            Zona(
                id: 'demo3',
                nombre: 'Laboratorio de Sistemas',
                latitud: 4.6100,
                longitud: -74.0820),
            Zona(
                id: 'demo4',
                nombre: 'Canchas Deportivas',
                latitud: 4.6105,
                longitud: -74.0825),
          ];
          _cargandoZonas = false;
        });
      }
    }
  }

  Future<void> _generarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_zonaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, seleccione una zona geográfica')),
      );
      return;
    }
    // Validar campos nuevos
    if (_fechaSeleccionada == null) {
      _mostrarError('Debe seleccionar una fecha.');
      return;
    }
    if (_horaInicio == null) {
      _mostrarError('Debe seleccionar una hora de inicio.');
      return;
    }
    if (_horaFin == null) {
      _mostrarError('Debe seleccionar una hora de fin.');
      return;
    }
    if (_horaFin!.hour < _horaInicio!.hour ||
        (_horaFin!.hour == _horaInicio!.hour &&
            _horaFin!.minute <= _horaInicio!.minute)) {
      _mostrarError('La hora de fin debe ser posterior a la hora de inicio.');
      return;
    }
    if (_tipoSeleccionado == null) {
      _mostrarError('Debe seleccionar un tipo de evento.');
      return;
    }

    setState(() {
      _creandoEvento = true;
      _errorCreacion = null;
    });
    try {
      final payload = {
        'materia': _materiaCtrl.text,
        'actividad': _actividadCtrl.text,
        'lugar': _lugarCtrl.text,
        'tipo': _tipoSeleccionado,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!),
        'horaInicio': _horaInicio!.format(context),
        'horaFin': _horaFin!.format(context),
        'zonaId': _zonaSeleccionada!.id,
        'zonaNombre': _zonaSeleccionada!.nombre,
        'latitud': _zonaSeleccionada!.latitud,
        'longitud': _zonaSeleccionada!.longitud,
      };

      final evento = await AsistenciaService.crearEvento(payload);
      if (mounted) {
        setState(() {
          _evento = evento;
          _creandoEvento = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creandoEvento = false;
          _errorCreacion = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _probarUbicacion() async {
    if (_zonaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, seleccione una zona geográfica primero.')),
      );
      return;
    }

    setState(() => _verificandoUbicacion = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están desactivados.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Los permisos de ubicación están permanentemente denegados.');
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      // Calcular distancia en metros
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _zonaSeleccionada!.latitud,
        _zonaSeleccionada!.longitud,
      );

      // Asumimos un radio de 50 metros para esta prueba
      bool isInside = distanceInMeters <= 50.0;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isInside
                              ? AppTheme.secondaryColor
                              : AppTheme.warningColor)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isInside
                          ? Icons.check_circle_outline
                          : Icons.location_off_outlined,
                      color: isInside
                          ? AppTheme.secondaryColor
                          : AppTheme.warningColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isInside ? '¡Ubicación Verificada!' : 'Fuera de la Zona',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distancia: ${distanceInMeters.toStringAsFixed(1)} metros',
                    style: TextStyle(
                      fontSize: 16,
                      color: isInside
                          ? AppTheme.secondaryColor
                          : AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text('Zona: ${_zonaSeleccionada!.nombre}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        Text('Lat: ${position.latitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                        Text('Lng: ${position.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInside
                            ? AppTheme.secondaryColor
                            : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Entendido',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error GPS: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verificandoUbicacion = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_evento == null
            ? 'Crear Evento de Asistencia'
            : 'Código QR Generado'),
      ),
      body: _evento != null ? _buildQrView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    if (_cargandoZonas) {
      return Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_errorZonas != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(_errorZonas!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _cargarZonas, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_zonas.isEmpty) {
      return const Center(
        child: Text('No hay zonas geográficas disponibles.'),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth),
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_modoDemo)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo Demo: Sin conexión al backend. Mostrando zonas de prueba.',
                        style: TextStyle(
                            color: AppTheme.warningColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Detalles del Evento',
              style: TextStyle(
                  color: AppTheme.gray900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Materia'),
            _buildTextField(_materiaCtrl, 'Ej: Programación II'),
            const SizedBox(height: 16),
            _buildFieldLabel('Actividad'),
            _buildTextField(_actividadCtrl, 'Ej: Examen Parcial'),
            const SizedBox(height: 16),
            _buildFieldLabel('Lugar / Aula'),
            _buildTextField(_lugarCtrl, 'Ej: Auditorio Central'),
            const SizedBox(height: 24),
            // ── Tipo de evento ──────────────────────────────────────────
            _buildFieldLabel('Tipo de evento *'),
            DropdownButtonFormField<String>(
              initialValue: _tipoSeleccionado,
              decoration:
                  const InputDecoration(hintText: 'Seleccione un tipo'),
              items: _tiposEvento.map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (val) =>
                  setState(() => _tipoSeleccionado = val),
              validator: (val) =>
                  val == null ? 'El tipo de evento es requerido' : null,
            ),
            const SizedBox(height: 16),
            // ── Fecha ───────────────────────────────────────────────────
            _buildFieldLabel('Fecha *'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  helpText: 'Selecciona la fecha del evento',
                );
                if (picked != null) {
                  setState(() => _fechaSeleccionada = picked);
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fechaSeleccionada != null
                          ? DateFormat('EEEE, d MMMM yyyy', 'es')
                              .format(_fechaSeleccionada!)
                          : 'Selecciona una fecha',
                      style: TextStyle(
                        color: _fechaSeleccionada != null
                            ? AppTheme.gray900
                            : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Horas ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Hora inicio *'),
                      _buildTimePicker(
                        tiempo: _horaInicio,
                        hint: 'Inicio',
                        onPicked: (t) =>
                            setState(() => _horaInicio = t),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Hora fin *'),
                      _buildTimePicker(
                        tiempo: _horaFin,
                        hint: 'Fin',
                        onPicked: (t) =>
                            setState(() => _horaFin = t),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Zona Geográfica (Requerido)'),
            DropdownButtonFormField<Zona>(
              initialValue: _zonaSeleccionada,
              decoration:
                  const InputDecoration(hintText: 'Seleccione una zona'),
              items: _zonas.map((zona) {
                return DropdownMenuItem(
                  value: zona,
                  child: Text(zona.nombre),
                );
              }).toList(),
              onChanged: (val) => setState(() => _zonaSeleccionada = val),
              validator: (val) => val == null ? 'La zona es requerida' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _verificandoUbicacion ? null : _probarUbicacion,
                icon: _verificandoUbicacion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location, color: Colors.white),
                label: Text(
                    _verificandoUbicacion
                        ? 'Verificando...'
                        : 'Probar mi ubicación GPS',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_errorCreacion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorCreacion!,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            CustomButton(
              text: 'Generar Código QR',
              isLoading: _creandoEvento,
              onPressed: _generarEvento,
            ),
          ],
        ),
      ),
    ),
  ),
  );
  }

  Widget _buildQrView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _evento!.materia,
              style: TextStyle(
                  color: AppTheme.gray900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _evento!.actividad,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // --- MOSTRAR ZONA ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Zona: ${_evento!.zonaNombre ?? 'No asignada'}',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 200,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Válido por 5:00 min',
              style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => setState(() => _evento = null),
              child: const Text('Crear otro evento',
                  style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
            color: AppTheme.gray900, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: hint),
      validator: (val) =>
          val == null || val.isEmpty ? 'Este campo es requerido' : null,
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay? tiempo,
    required String hint,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: tiempo ?? TimeOfDay.now(),
          helpText: 'Selecciona la hora',
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tiempo != null ? tiempo.format(context) : hint,
              style: TextStyle(
                color: tiempo != null ? AppTheme.gray900 : Colors.grey,
              ),
            ),
            const Icon(Icons.access_time, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
