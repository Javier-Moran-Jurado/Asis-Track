import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final Rect? selection;
  final Color borderColor;
  final Color fillColor;

  CropOverlayPainter({
    required this.selection,
    this.borderColor = const Color(0xFF2563EB),
    this.fillColor = const Color(0x332563EB),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selection == null) return;
    final rect = selection!;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _drawDashedRect(canvas, rect, borderPaint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addRect(rect);
    const dashLength = 8.0;
    const dashGap = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.selection != selection ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor;
  }
}
