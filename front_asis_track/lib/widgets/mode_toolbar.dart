// lib/widgets/mode_toolbar.dart
import 'package:flutter/material.dart';

import '../providers/planilla_provider.dart';
import '../themes/app_theme.dart';

class ModeToolbar extends StatelessWidget {
  final ImageMode mode;
  final bool hasSignatureField;
  final ValueChanged<ImageMode> onModeChanged;

  const ModeToolbar({
    super.key,
    required this.mode,
    required this.hasSignatureField,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.pan_tool_alt_outlined,
            label: 'Mover',
            selected: mode == ImageMode.panZoom,
            onTap: () => onModeChanged(ImageMode.panZoom),
          ),
          if (hasSignatureField) ...[
            const SizedBox(width: 6),
            _ModeButton(
              icon: Icons.crop,
              label: 'Recortar',
              selected: mode == ImageMode.cropSignature,
              onTap: () => onModeChanged(ImageMode.cropSignature),
            ),
          ],
          const SizedBox(width: 6),
          _ModeButton(
            icon: Icons.remove_red_eye_outlined,
            label: 'Referencia',
            selected: mode == ImageMode.referenceOnly,
            onTap: () => onModeChanged(ImageMode.referenceOnly),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryColor : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
