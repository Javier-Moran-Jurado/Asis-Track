import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';

class StatusChipData {
  final String text;
  final Color color;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;

  StatusChipData({
    required this.text,
    required this.color,
    this.icon,
    this.backgroundColor,
    this.borderColor,
  });
}

class DynamicInfoCard extends StatelessWidget {
  final String title;
  final String? topSubtitle;
  final DateTime? date;
  final List<StatusChipData> statusChips;
  final Widget? extraContent;
  final List<Widget>? actionButtons;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  const DynamicInfoCard({
    super.key,
    required this.title,
    this.topSubtitle,
    this.date,
    this.statusChips = const [],
    this.extraContent,
    this.actionButtons,
    this.onTap,
    this.leadingIcon,
    this.leadingIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Fecha y Subtítulo/Categoría
              if (date != null || topSubtitle != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (date != null)
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm', 'es').format(date!),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (topSubtitle != null)
                      Text(
                        topSubtitle!,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Título (y opcionalmente icono a la izquierda)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (leadingIconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        leadingIcon,
                        size: 22,
                        color: leadingIconColor ?? AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.gray900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (extraContent != null) ...[
                const SizedBox(height: 12),
                extraContent!,
              ],

              // Fila inferior: Chips de estado
              if (statusChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statusChips.map((chip) => _buildStatusChip(chip)).toList(),
                ),
              ],

              // Botones de acción
              if (actionButtons != null && actionButtons!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: actionButtons!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(StatusChipData chip) {
    final bgColor = chip.backgroundColor ?? chip.color.withValues(alpha: 0.1);
    final borderColor = chip.borderColor ?? chip.color.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip.icon != null) ...[
            Icon(chip.icon, size: 14, color: chip.color),
            const SizedBox(width: 4),
          ],
          Text(
            chip.text,
            style: TextStyle(
              color: chip.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
