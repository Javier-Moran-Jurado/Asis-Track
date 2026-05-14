import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

class ConfirmCropButton extends StatelessWidget {
  final Rect selection;
  final Size bounds;
  final VoidCallback onPressed;
  final bool isLoading;

  const ConfirmCropButton({
    super.key,
    required this.selection,
    required this.bounds,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 170.0;
    const buttonHeight = 36.0;
    const offset = 8.0;

    final left = (selection.right + offset)
        .clamp(8.0, bounds.width - buttonWidth - 8.0);
    final top = (selection.bottom + offset)
        .clamp(8.0, bounds.height - buttonHeight - 8.0);

    return Positioned(
      left: left,
      top: top,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Confirmar recorte'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
