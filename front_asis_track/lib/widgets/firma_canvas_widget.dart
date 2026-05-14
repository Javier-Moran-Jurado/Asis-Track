import 'package:flutter/material.dart';

/// Lienzo reutilizable para dibujar una firma digital con el dedo.
///
/// Uso:
/// ```dart
/// FirmaCanvasWidget(
///   onFirmaChanged: (tieneFirma) { ... },
///   onClear: () { ... },
/// )
/// ```
class FirmaCanvasWidget extends StatefulWidget {
  /// Callback que se llama cuando la firma cambia (vacío ↔ con contenido).
  final ValueChanged<bool>? onFirmaChanged;

  /// Callback cuando se solicita limpiar el lienzo.
  final VoidCallback? onClear;

  const FirmaCanvasWidget({
    super.key,
    this.onFirmaChanged,
    this.onClear,
  });

  @override
  State<FirmaCanvasWidget> createState() => _FirmaCanvasWidgetState();
}

class _FirmaCanvasWidgetState extends State<FirmaCanvasWidget> {
  final GlobalKey _canvasKey = GlobalKey();
  List<List<Offset>> _firmas = [];

  bool get tieneFirma => _firmas.isNotEmpty;

  void agregarFirma(Offset punto) {
    if (_firmas.isEmpty) _firmas.add([]);
    _firmas.last = [..._firmas.last, punto];
    widget.onFirmaChanged?.call(true);
    setState(() {});
  }

  void nuevaLinea() {
    if (_firmas.isNotEmpty && _firmas.last.isNotEmpty) {
      _firmas.add([]);
      setState(() {});
    }
  }

  void limpiar() {
    _firmas = [];
    widget.onFirmaChanged?.call(false);
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _canvasKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          final RenderBox box =
              _canvasKey.currentContext!.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          agregarFirma(localPosition);
        },
        onPanEnd: (_) => nuevaLinea(),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _FirmaPainter(firmas: _firmas),
                size: Size.infinite,
              ),
            ),
            if (_firmas.isEmpty)
              const Center(
                child: Text(
                  'Firma aquí con tu dedo',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter que dibuja las líneas de la firma.
class _FirmaPainter extends CustomPainter {
  final List<List<Offset>> firmas;

  _FirmaPainter({required this.firmas});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final linea in firmas) {
      if (linea.isEmpty) continue;
      final path = Path();
      path.moveTo(linea.first.dx, linea.first.dy);
      for (int i = 1; i < linea.length; i++) {
        path.lineTo(linea[i].dx, linea[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter oldDelegate) => true;
}
