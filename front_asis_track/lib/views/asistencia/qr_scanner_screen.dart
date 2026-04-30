import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../services/asistencia_service.dart';

/// Pantalla de la cámara QR con overlay de guía de escaneo.
/// Navega automáticamente a la pantalla de detalle al detectar un QR válido.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  // ─── Colores ─────────────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF0F172A);

  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false; // evita escaneos múltiples simultáneos
  bool _torchOn = false;

  // Animación del marco de escaneo
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  // ─── Lógica de escaneo ───────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _scannerCtrl.stop();

    try {
      // Muestra indicador de carga mientras valida con el backend
      if (!mounted) return;
      _showLoadingDialog();

      final evento = await AsistenciaService.validarQr(code);

      if (!mounted) return;
      Navigator.of(context).pop(); // cierra el loading

      // Navega al detalle pasando el evento como extra
      context.push('/asistencia/detalle', extra: evento);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // cierra el loading
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      // Reanuda el escáner para que el usuario pueda reintentar
      await _scannerCtrl.start();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 18),
              Text(
                'Validando código QR...',
                style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Apunta al código QR',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? Colors.yellow : Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {
              _scannerCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ── Cámara ──────────────────────────────────────────────────────
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // ── Overlay oscuro con ventana transparente ──────────────────────
          _ScanOverlay(pulseAnim: _pulseAnim),

          // ── Texto de ayuda abajo ─────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Opacity(
                    opacity: _pulseAnim.value,
                    child: child,
                  ),
                  child: const Text(
                    'Alineando código QR...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El escaneo es automático cuando se detecta un QR válido.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay con recorte central y marco animado
// ─────────────────────────────────────────────────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _ScanOverlay({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    const cutSize = 260.0;
    return Stack(
      children: [
        // Sombra oscura alrededor del recuadro
        CustomPaint(
          painter: _OverlayPainter(cutSize: cutSize),
          child: const SizedBox.expand(),
        ),
        // Marco de escaneo animado centrado
        Center(
          child: AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(scale: pulseAnim.value, child: child),
            child: SizedBox(
              width: cutSize,
              height: cutSize,
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pinta el fondo semitransparente dejando un recorte transparente en el centro.
class _OverlayPainter extends CustomPainter {
  final double cutSize;
  const _OverlayPainter({required this.cutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: cutSize, height: cutSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Pinta las 4 esquinas del marco de escaneo.
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const cornerRadius = 6.0;
    const strokeW = 3.5;
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Esquina superior-izquierda
    canvas.drawPath(
      Path()
        ..moveTo(cornerRadius, cornerLength)
        ..lineTo(cornerRadius, cornerRadius)
        ..lineTo(cornerLength, cornerRadius),
      paint,
    );
    // Esquina superior-derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, cornerRadius)
        ..lineTo(size.width - cornerRadius, cornerRadius)
        ..lineTo(size.width - cornerRadius, cornerLength),
      paint,
    );
    // Esquina inferior-izquierda
    canvas.drawPath(
      Path()
        ..moveTo(cornerRadius, size.height - cornerLength)
        ..lineTo(cornerRadius, size.height - cornerRadius)
        ..lineTo(cornerLength, size.height - cornerRadius),
      paint,
    );
    // Esquina inferior-derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height - cornerRadius)
        ..lineTo(size.width - cornerRadius, size.height - cornerRadius)
        ..lineTo(size.width - cornerRadius, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
