import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_theme.dart';
import '../utils/app_breakpoints.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Scaffold(
        body: child,
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/logo_asis_track.png',
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'Asis-Track',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          _buildNavigationRail(context),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Navegación inferior para móvil.
  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/asistencia')) currentIndex = 1;
    if (location.startsWith('/historial')) currentIndex = 2;
    if (location.startsWith('/justificaciones')) currentIndex = 3;
    if (location.startsWith('/perfil')) currentIndex = 4;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/asistencia');
          case 2:
            context.go('/historial');
          case 3:
            context.go('/justificaciones');
          case 4:
            context.go('/perfil');
        }
      },
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Asistencia'),
        BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial'),
        BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Justificaciones'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil'),
      ],
    );
  }

  /// NavigationRail para tablet/desktop.
  Widget _buildNavigationRail(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/asistencia')) currentIndex = 1;
    if (location.startsWith('/historial')) currentIndex = 2;
    if (location.startsWith('/justificaciones')) currentIndex = 3;
    if (location.startsWith('/perfil')) currentIndex = 4;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/asistencia');
          case 2:
            context.go('/historial');
          case 3:
            context.go('/justificaciones');
          case 4:
            context.go('/perfil');
        }
      },
      labelType: NavigationRailLabelType.selected,
      backgroundColor: Colors.white,
      selectedIconTheme:
          const IconThemeData(color: AppTheme.primaryColor, size: 24),
      unselectedIconTheme:
          IconThemeData(color: Colors.grey.shade600, size: 24),
      selectedLabelTextStyle: const TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 12,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: Text('Asistencia'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Historial'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: Text('Justific.'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Perfil'),
        ),
      ],
    );
  }
}
