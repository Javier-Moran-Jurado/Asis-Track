import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, 'Inicio'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido/a, Juan Pérez',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Qué necesitas hacer hoy?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  // For very small screens, maybe use a column, but Row with Wrap or Expanded is fine
                  return Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'Registrar\nasistencia',
                          onTap: () => context.push('/asistencia'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.description_outlined,
                          title: 'Solicitar\njustificación',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.person_outline,
                          title: 'Ver\nperfil',
                          onTap: () => context.push('/perfil'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String currentRoute) {
    return AppBar(
      titleSpacing: 16,
      title: const Text(
        'AsisTrack',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: false, // Hide back button if any
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
