import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    
    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/asistencia')) currentIndex = 1;
    if (location.startsWith('/justificaciones')) currentIndex = 2;
    if (location.startsWith('/perfil')) currentIndex = 3;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) context.go('/home');
        if (index == 1) context.go('/asistencia');
        if (index == 2) context.go('/justificaciones');
        if (index == 3) context.go('/perfil');
      },
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner_outlined),
          activeIcon: Icon(Icons.qr_code_scanner),
          label: 'Asistencia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Justificaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
