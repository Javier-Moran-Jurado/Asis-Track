import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../models/evento_qr.dart';
import '../../services/asistencia_service.dart';

/// Pantalla de detalle que muestra la información del evento del QR escaneado.
/// Permite al estudiante confirmar y registrar su asistencia.
class AsistenciaDetalleScreen extends StatefulWidget {
  final EventoQr evento;

  const AsistenciaDetalleScreen({super.key, required this.evento});

  @override
  State<AsistenciaDetalleScreen> createState() => _AsistenciaDetalleScreenState();
}

class _AsistenciaDetalleScreenState extends State<AsistenciaDetalleScreen>
    with SingleTickerProviderStateMixin {
  // ─── Colores ─────────────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _bgCard = Color(0xFF1E293B);
  static const Color _textLight = Color(0xFFE2E8F0);

  bool _registrando = false;
  String? _resultadoMensaje;
  bool _esExito = false;
  double? _latitud;
  double? _longitud;
  bool _gpsObtenido = false;

  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  // ─── GPS ─────────────────────────────────────────────────────────────────
  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() {
          _latitud = pos.latitude;
          _longitud = pos.longitude;
          _gpsObtenido = true;
        });
      }
    } catch (_) {
      // GPS no disponible: se procede sin él
    }
  }

  // ─── Registro de asistencia ───────────────────────────────────────────────
  Future<void> _registrarAsistencia() async {
    if (_registrando) return;
    setState(() => _registrando = true);

    try {
      final mensaje = await AsistenciaService.registrarAsistencia(
        tokenQr: widget.evento.tokenQr,
        estudianteId: 'estudiante-demo-001', // Reemplazar con el ID real del usuario autenticado
        latitud: _latitud,
        longitud: _longitud,
      );
      if (!mounted) return;
      setState(() {
        _resultadoMensaje = mensaje;
        _esExito = true;
        _registrando = false;
      });
      _checkCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultadoMensaje = e.toString().replaceFirst('Exception: ', '');
        _esExito = false;
        _registrando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textLight, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detalles del Evento',
          style: TextStyle(color: _textLight, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _resultadoMensaje != null
          ? _ResultadoView(
              mensaje: _resultadoMensaje!,
              esExito: _esExito,
              checkScale: _checkScale,
              onVolver: () => context.go('/asistencia'),
              onReintentar: _esExito ? null : () => setState(() => _resultadoMensaje = null),
            )
          : _DetalleContent(
              evento: widget.evento,
              gpsObtenido: _gpsObtenido,
              registrando: _registrando,
              onRegistrar: _registrarAsistencia,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de detalles del evento
// ─────────────────────────────────────────────────────────────────────────────
class _DetalleContent extends StatelessWidget {
  final EventoQr evento;
  final bool gpsObtenido;
  final bool registrando;
  final VoidCallback onRegistrar;

  static const Color _primary = Color(0xFF2563EB);
  static const Color _bgCard = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF94A3B8);
  static const Color _border = Color(0xFF334155);

  const _DetalleContent({
    required this.evento,
    required this.gpsObtenido,
    required this.registrando,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ── Badge de estado ───────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Color(0xFF4ADE80), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'QR Válido',
                    style: TextStyle(
                        color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Tarjeta principal de evento ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del Evento',
                  style: TextStyle(
                      color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.8),
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.school, label: 'Materia', value: evento.materia),
                _Divider(),
                _InfoRow(icon: Icons.event, label: 'Actividad', value: evento.actividad),
                _Divider(),
                _InfoRow(icon: Icons.calendar_today, label: 'Fecha', value: evento.fecha),
                _Divider(),
                _InfoRow(icon: Icons.access_time, label: 'Hora', value: evento.hora),
                _Divider(),
                _InfoRow(icon: Icons.location_on, label: 'Lugar', value: evento.lugar),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Badge de GPS ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(
                  gpsObtenido ? Icons.gps_fixed : Icons.gps_off,
                  color: gpsObtenido ? const Color(0xFF4ADE80) : _textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  gpsObtenido
                      ? 'Ubicación GPS obtenida — se adjuntará al registro'
                      : 'GPS no disponible — se registrará sin ubicación',
                  style: TextStyle(
                    color: gpsObtenido ? const Color(0xFF4ADE80) : _textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Botón registrar ───────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: registrando
                ? const SizedBox(
                    height: 56,
                    key: ValueKey('loading'),
                    child: Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                : _RegisterButton(key: const ValueKey('button'), onTap: onRegistrar),
          ),

          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 16),
            label: const Text('Volver a escanear'),
            style: TextButton.styleFrom(foregroundColor: _textMuted),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color(0xFF2563EB);
  static const Color _textLight = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF94A3B8);

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF60A5FA), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      color: _textLight, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: Color(0xFF334155), height: 1, thickness: 0.5);
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback onTap;

  static const Color _secondary = Color(0xFF16A34A);

  const _RegisterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _secondary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Registrar asistencia',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de resultado (éxito o error)
// ─────────────────────────────────────────────────────────────────────────────
class _ResultadoView extends StatelessWidget {
  final String mensaje;
  final bool esExito;
  final Animation<double> checkScale;
  final VoidCallback onVolver;
  final VoidCallback? onReintentar;

  const _ResultadoView({
    required this.mensaje,
    required this.esExito,
    required this.checkScale,
    required this.onVolver,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final color = esExito ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon = esExito ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final titulo = esExito ? '¡Asistencia Registrada!' : 'No se pudo registrar';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: checkScale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 64),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Volver al inicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: onVolver,
              ),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
                onPressed: onReintentar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
