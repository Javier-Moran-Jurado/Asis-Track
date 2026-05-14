// lib/screens/preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/planilla_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/planilla_preview_layout.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _saving = false;

  Future<void> _save(WidgetRef ref) async {
    setState(() => _saving = true);
    try {
      final notifier = ref.read(planillaProvider.notifier);
      final state = ref.read(planillaProvider);
      final planilla = state.planilla;
      if (planilla == null) return;

      await notifier.savePlanilla();

      final savedNotifier = ref.read(savedPlanillasProvider.notifier);
      savedNotifier.save(planilla);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado ✅'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        context.go('/planillas');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planillaProvider);
    final planilla = state.planilla;

    if (planilla == null) {
      return Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(title: const Text('Vista previa')),
        body: const Center(child: Text('No hay datos para mostrar.')),
      );
    }

    final fecha = DateFormat("d 'de' MMMM yyyy", 'es').format(planilla.date);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planilla.eventName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              fecha,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Exportar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportando…')),
              );
            },
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            tooltip: 'Guardar',
            onPressed: _saving ? null : () => _save(ref),
          ),
        ],
      ),
      body: PlanillaPreviewLayout(planilla: planilla),
    );
  }
}
