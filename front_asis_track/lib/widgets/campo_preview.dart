import 'package:flutter/material.dart';
import '../models/planilla.dart';
import '../themes/app_theme.dart';

/// Widget de previsualización de un campo.
///
/// Renderiza una vista read-only según el tipo de campo:
/// - text → TextField deshabilitado
/// - numeric → TextField numérico deshabilitado
/// - date → widget de fecha deshabilitado
/// - email → TextField con ícono de email
/// - secret → TextField con puntos
/// - checkbox → Checkbox deshabilitado
/// - multivaluecheckbox → Lista de Checkboxes deshabilitados
/// - combo → DropdownButton deshabilitado
/// - radio → Radio buttons deshabilitados
/// - signature_file → Área de firma
/// - file → Botón de archivo
/// - Otros tipos → TextField genérico con label del tipo
class CampoPreview extends StatelessWidget {
  final CampoPreviewModel campo;

  const CampoPreview({super.key, required this.campo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _colorTipo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_iconoTipo, size: 18, color: _colorTipo),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  campo.nombreCampo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900),
                ),
              ),
              if (campo.obligatorio)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Obligatorio', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  campo.tipoCampo.nombreEspanol,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreview(),
        ],
      ),
    );
  }

  Color get _colorTipo {
    switch (campo.tipoCampo.tipo) {
      case 'text': return AppTheme.primaryColor;
      case 'numeric': return const Color(0xFF7C3AED);
      case 'date': return const Color(0xFFEA580C);
      case 'email': return const Color(0xFF2563EB);
      case 'secret': return const Color(0xFF64748B);
      case 'checkbox': return AppTheme.secondaryColor;
      case 'multivaluecheckbox': return AppTheme.secondaryColor;
      case 'combo': return const Color(0xFF0891B2);
      case 'radio': return const Color(0xFFDB2777);
      case 'signature_file': return const Color(0xFF4F46E5);
      case 'file': return const Color(0xFF92400E);
      default: return Colors.grey;
    }
  }

  IconData get _iconoTipo {
    switch (campo.tipoCampo.tipo) {
      case 'text': return Icons.text_fields;
      case 'numeric': return Icons.numbers;
      case 'date': return Icons.calendar_today;
      case 'email': return Icons.email_outlined;
      case 'secret': return Icons.lock_outline;
      case 'checkbox': return Icons.check_box_outlined;
      case 'multivaluecheckbox': return Icons.checklist;
      case 'combo': return Icons.arrow_drop_down_circle_outlined;
      case 'radio': return Icons.radio_button_checked;
      case 'signature_file': return Icons.draw_outlined;
      case 'file': return Icons.attach_file;
      default: return Icons.help_outline;
    }
  }

  Widget _buildPreview() {
    switch (campo.tipoCampo.tipo) {
      case 'text':
        return _inputPreview(
          child: Text('Texto de ejemplo', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        );

      case 'numeric':
        return _inputPreview(
          child: Text('123456', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        );

      case 'date':
        return _inputPreview(
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text('Seleccionar fecha', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        );

      case 'email':
        return _inputPreview(
          child: Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text('correo@ejemplo.com', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        );

      case 'secret':
        return _inputPreview(
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text('••••••••', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        );

      case 'checkbox':
        return Row(
          children: [
            SizedBox(
              height: 20, width: 20,
              child: Checkbox(value: false, onChanged: null, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
            const SizedBox(width: 8),
            Text('Opción', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        );

      case 'multivaluecheckbox':
        if (campo.opciones.isEmpty) {
          return _emptyOptions();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: campo.opciones.map((opt) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  height: 20, width: 20,
                  child: Checkbox(value: false, onChanged: null, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                const SizedBox(width: 8),
                Text(opt, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          )).toList(),
        );

      case 'combo':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: campo.opciones.isNotEmpty ? campo.opciones.first : null,
            items: campo.opciones.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: null,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text('Seleccionar...', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ),
        );

      case 'radio':
        if (campo.opciones.isEmpty) {
          return _emptyOptions();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: campo.opciones.map((opt) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  height: 20, width: 20,
                  child: Radio<String>(value: opt, groupValue: '', onChanged: null, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                const SizedBox(width: 8),
                Text(opt, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          )).toList(),
        );

      case 'signature_file':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.draw_outlined, size: 24, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text('Firma digital', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        );

      case 'file':
        return _inputPreview(
          child: Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text('Seleccionar archivo', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        );

      default:
        return _inputPreview(
          child: Text(
            'Campo: ${campo.tipoCampo.tipo}',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        );
    }
  }

  Widget _inputPreview({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _emptyOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.warningColor.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text(
            'Sin opciones configuradas',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
