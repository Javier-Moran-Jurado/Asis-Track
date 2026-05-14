// lib/widgets/planilla_preview_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/planilla_digital.dart';
import '../providers/planilla_provider.dart';
import '../themes/app_theme.dart';
import 'digitized_data_panel.dart';
import 'reference_image_panel.dart';

class PlanillaPreviewLayout extends ConsumerStatefulWidget {
  final PlanillaDigital planilla;

  const PlanillaPreviewLayout({super.key, required this.planilla});

  @override
  ConsumerState<PlanillaPreviewLayout> createState() =>
      _PlanillaPreviewLayoutState();
}

class _PlanillaPreviewLayoutState extends ConsumerState<PlanillaPreviewLayout> {
  double _wideRatio = 0.75;
  double? _topHeight;
  bool _wideDragActive = false;
  bool _narrowDragActive = false;

  static const double _minPanel = 120.0;
  static const double _minWideRatio = 0.15;
  static const double _maxWideRatio = 0.85;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planillaProvider);
    final notifier = ref.read(planillaProvider.notifier);
    final hasSig = widget.planilla.hasSignatureField;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isWide = width >= 720;

        if (isWide) {
          return _buildWideLayout(width, height, state, notifier, hasSig);
        }
        return _buildNarrowLayout(width, height, state, notifier, hasSig);
      },
    );
  }

  Widget _buildWideLayout(double width, double height, PlanillaDigitalState state,
      PlanillaNotifier notifier, bool hasSig) {
    const handleWidth = 20.0;
    final usableWidth = width - handleWidth;
    final leftWidth = (usableWidth * _wideRatio)
        .clamp(usableWidth * _minWideRatio, usableWidth * _maxWideRatio);
    final rightWidth = usableWidth - leftWidth;

    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ReferenceImagePanel(planilla: widget.planilla),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            final center = handleWidth / 2;
            if ((details.localPosition.dx - center).abs() <= 12) {
              _wideDragActive = true;
            }
          },
          onPanUpdate: (details) {
            if (!_wideDragActive) return;
            setState(() {
              _wideRatio = (leftWidth + details.delta.dx) / usableWidth;
              _wideRatio = _wideRatio.clamp(_minWideRatio, _maxWideRatio);
            });
          },
          onPanEnd: (_) => _wideDragActive = false,
          child: Container(
            width: handleWidth,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        SizedBox(
          width: rightWidth,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DigitizedDataPanel(
              records: widget.planilla.records,
              targetIndex: state.targetRecordIndex,
              hasSignatureField: hasSig,
              fieldDefs: widget.planilla.fieldDefs,
              onSignatureTap: (index) {
                notifier.setTargetRecord(index);
                notifier.setMode(ImageMode.cropSignature);
              },
              onRecordChanged: (index, record) {
                notifier.updateRecord(index, record);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(double width, double height, PlanillaDigitalState state,
      PlanillaNotifier notifier, bool hasSig) {
    const handleHeight = 12.0;
    final usableHeight = height - handleHeight;
    _topHeight ??= usableHeight * 0.75;
    final topHeight = _topHeight!.clamp(_minPanel, usableHeight - _minPanel);
    final bottomHeight = usableHeight - topHeight;

    return Column(
      children: [
        SizedBox(
          height: topHeight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ReferenceImagePanel(planilla: widget.planilla),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            final center = handleHeight / 2;
            if ((details.localPosition.dy - center).abs() <= 12) {
              _narrowDragActive = true;
            }
          },
          onPanUpdate: (details) {
            if (!_narrowDragActive) return;
            setState(() {
              _topHeight = (_topHeight! + details.delta.dy)
                  .clamp(_minPanel, usableHeight - _minPanel);
            });
          },
          onPanEnd: (_) => _narrowDragActive = false,
          child: Container(
            height: handleHeight,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        SizedBox(
          height: bottomHeight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DigitizedDataPanel(
              records: widget.planilla.records,
              targetIndex: state.targetRecordIndex,
              hasSignatureField: hasSig,
              fieldDefs: widget.planilla.fieldDefs,
              onSignatureTap: (index) {
                notifier.setTargetRecord(index);
                notifier.setMode(ImageMode.cropSignature);
              },
              onRecordChanged: (index, record) {
                notifier.updateRecord(index, record);
              },
            ),
            ),
          ),
        ],
      );
  }
}
