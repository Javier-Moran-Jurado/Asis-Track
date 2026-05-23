import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';

class InvitadoScannerScreen extends StatefulWidget {
  const InvitadoScannerScreen({super.key});

  @override
  State<InvitadoScannerScreen> createState() => _InvitadoScannerScreenState();
}

class _InvitadoScannerScreenState extends State<InvitadoScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _torchOn = false;

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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _scannerCtrl.stop();

    // Parse the QR code: can be a URL like "http://host/#/formulario/5"
    String? planillaId;
    try {
      final uri = Uri.parse(code);
      if (uri.fragment.isNotEmpty) {
        final frag = uri.fragment; // e.g. "/formulario/5"
        final match = RegExp(r'/formulario/(\d+)').firstMatch(frag);
        if (match != null) {
          planillaId = match.group(1);
        }
      }
    } catch (_) {
      // ignore parse errors
    }

    if (planillaId != null) {
      if (!mounted) return;
      await context.push('/planillas/llenar', extra: int.tryParse(planillaId));
    } else {
      // Unknown QR code — just show message and resume scanning
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Código QR no reconocido. Escanea un código de planilla.'),
        ));
      }
    }

    if (mounted) {
      await _scannerCtrl.start();
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Escanear QR de Planilla',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/planillas'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.white,
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
          // Cámara de escaneo
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // Overlay oscuro con recorte central
          _ScanOverlay(pulseAnim: _pulseAnim),

          // Controles y texto instructivo
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
                    'Alinea el código QR del evento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El código se escaneará automáticamente para abrir el formulario de asistencia.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
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

class _ScanOverlay extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _ScanOverlay({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    const cutSize = 260.0;
    return Stack(
      children: [
        CustomPaint(
          painter: _OverlayPainter(cutSize: cutSize),
          child: const SizedBox.expand(),
        ),
        Center(
          child: AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: pulseAnim.value, child: child),
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

class _OverlayPainter extends CustomPainter {
  final double cutSize;
  const _OverlayPainter({required this.cutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: cutSize, height: cutSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const cornerRadius = 6.0;
    const strokeW = 4.0;
    final paint = Paint()
      ..color = AppTheme.primaryColor
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
