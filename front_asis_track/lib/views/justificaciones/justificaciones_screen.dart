import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

class JustificacionesScreen extends StatelessWidget {
  const JustificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'AsisTrack - Justificaciones',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Próximamente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900),
            ),
            const SizedBox(height: 8),
            const Text(
              'El módulo de justificaciones está en desarrollo.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
