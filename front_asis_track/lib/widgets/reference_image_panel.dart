// lib/widgets/reference_image_panel.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/planilla_digital.dart';
import '../providers/planilla_provider.dart';
import '../themes/app_theme.dart';
import 'confirm_crop_button.dart';
import 'crop_overlay_painter.dart';
import 'mode_toolbar.dart';
import 'signature_assignment_sheet.dart';

class ReferenceImagePanel extends ConsumerStatefulWidget {
  final PlanillaDigital planilla;

  const ReferenceImagePanel({super.key, required this.planilla});

  @override
  ConsumerState<ReferenceImagePanel> createState() =>
      _ReferenceImagePanelState();
}

class _ReferenceImagePanelState extends ConsumerState<ReferenceImagePanel> {
  Offset? _dragStart;
  Size _viewportSize = Size.zero;
  bool _processing = false;

  void _updateViewportSize(Size size, PlanillaNotifier notifier) {
    if (_viewportSize == size) return;
    _viewportSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.resetTransformForImage(size);
    });
  }

  Rect? _imageToViewport(Rect imageRect, Matrix4 matrix) {
    final tl = MatrixUtils.transformPoint(matrix, imageRect.topLeft);
    final br = MatrixUtils.transformPoint(matrix, imageRect.bottomRight);
    final rect = Rect.fromPoints(tl, br);
    return rect.isFinite ? rect : null;
  }

  Rect _viewportToImage(Rect viewportRect, Matrix4 matrix, PlanillaNotifier notifier) {
    final inverted = Matrix4.inverted(matrix);
    final tl = MatrixUtils.transformPoint(inverted, viewportRect.topLeft);
    final br = MatrixUtils.transformPoint(inverted, viewportRect.bottomRight);
    return notifier.clampToImage(Rect.fromPoints(tl, br));
  }

  Future<Uint8List?> _cropToBytes(Rect imageRect, ui.Image image) async {
    final w = math.max(1, imageRect.width.round());
    final h = math.max(1, imageRect.height.round());
    final src = Rect.fromLTWH(imageRect.left, imageRect.top, imageRect.width, imageRect.height);
    final dst = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(image, src, dst, Paint());
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(w, h);
    final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _confirmCrop(PlanillaNotifier notifier, PlanillaDigitalState state) async {
    if (_processing) return;
    final selection = state.cropSelection;
    if (selection == null) return;
    setState(() => _processing = true);

    final bytes = await _cropToBytes(selection, widget.planilla.referenceImage);
    if (bytes == null) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo recortar la imagen')),
        );
      }
      return;
    }

    int? target = state.targetRecordIndex;
    if (target == null) {
      final selected = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SignatureAssignmentSheet(
          records: widget.planilla.records,
          onSelect: (index) => Navigator.pop(context, index),
        ),
      );
      target = selected;
    }

    if (target != null && target >= 0 && target < widget.planilla.records.length) {
      final nombre = widget.planilla.records[target].nombreCompleto;
      try {
        await notifier.confirmCrop(bytes, target);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firma de $nombre actualizada ✅')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar firma: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) setState(() => _processing = false);
  }

  void _onModeChanged(ImageMode mode, PlanillaNotifier notifier) {
    if (!widget.planilla.hasSignatureField && mode == ImageMode.cropSignature) return;
    notifier.setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planillaProvider);
    final notifier = ref.read(planillaProvider.notifier);
    final hasSig = widget.planilla.hasSignatureField;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _updateViewportSize(size, notifier);

        final matrix = notifier.transformationController.value;
        final selectionViewport = state.cropSelection == null
            ? null
            : _imageToViewport(state.cropSelection!, matrix);
        final showOverlay = state.mode == ImageMode.cropSignature;

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AbsorbPointer(
                absorbing: state.mode == ImageMode.cropSignature,
                child: InteractiveViewer(
                  transformationController: notifier.transformationController,
                  minScale: 0.5,
                  maxScale: 6,
                  boundaryMargin: const EdgeInsets.all(100),
                  constrained: false,
                  child: SizedBox(
                    width: widget.planilla.referenceImage.width.toDouble(),
                    height: widget.planilla.referenceImage.height.toDouble(),
                    child: RawImage(
                      image: widget.planilla.referenceImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            if (showOverlay && hasSig)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    _dragStart = details.localPosition;
                    notifier.setCropSelection(null);
                  },
                  onPanUpdate: (details) {
                    if (_dragStart == null) return;
                    final rect = Rect.fromPoints(_dragStart!, details.localPosition);
                    final imgRect = _viewportToImage(rect, matrix, notifier);
                    notifier.setCropSelection(imgRect);
                  },
                  onPanEnd: (_) => _dragStart = null,
                ),
              ),
            if (showOverlay && hasSig && selectionViewport != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(selection: selectionViewport),
                ),
              ),
            if (showOverlay && hasSig && selectionViewport != null)
              ConfirmCropButton(
                selection: selectionViewport,
                bounds: size,
                onPressed: _processing
                    ? () {}
                    : () => _confirmCrop(notifier, state),
                isLoading: _processing,
              ),
            Positioned(
              top: 12,
              left: 12,
              child: ModeToolbar(
                mode: state.mode,
                hasSignatureField: hasSig,
                onModeChanged: (mode) => _onModeChanged(mode, notifier),
              ),
            ),
          ],
        );
      },
    );
  }
}
