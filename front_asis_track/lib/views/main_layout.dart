import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/role_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_breakpoints.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rol = auth.currentUser?.rol ?? '';
    final showUsuarios = RoleService.canCreateUsers(rol);
    final showEventos = RoleService.canCreateEvents(rol);
    final showLugares = RoleService.canCreateUsers(rol); // mismo permiso que crear usuarios

    if (AppBreakpoints.isMobile(context)) {
      return Scaffold(
        body: child,
        bottomNavigationBar: _buildBottomNav(context, showUsuarios, showEventos, showLugares),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/logo_asis_track.png', height: 32),
            const SizedBox(width: 10),
            const Text('Asis-Track', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          _buildNavigationRail(context, showUsuarios, showEventos, showLugares),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_NavItem> _buildItems(bool showUsuarios, bool showEventos, bool showLugares) {
    return [
      _NavItem('/home', Icons.home_outlined, Icons.home, 'Inicio'),
      _NavItem('/asistencia', Icons.qr_code_scanner_outlined, Icons.qr_code_scanner, 'Asistencia'),
      _NavItem('/historial', Icons.history_outlined, Icons.history, 'Historial'),
      _NavItem('/justificaciones', Icons.description_outlined, Icons.description, 'Justificaciones'),
      if (showEventos)
        _NavItem('/eventos', Icons.event_outlined, Icons.event, 'Eventos'),
      if (showLugares)
        _NavItem('/lugares', Icons.place_outlined, Icons.place, 'Lugares'),
      if (showUsuarios)
        _NavItem('/usuarios', Icons.people_outline, Icons.people, 'Usuarios'),
      _NavItem('/perfil', Icons.person_outline, Icons.person, 'Perfil'),
    ];
  }

  Widget _buildBottomNav(BuildContext context, bool showUsuarios, bool showEventos, bool showLugares) {
    final items = _buildItems(showUsuarios, showEventos, showLugares);
    final location = GoRouterState.of(context).uri.path;
    int idx = 0;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) idx = i;
    }
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: idx,
      onTap: (i) => context.go(items[i].path),
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: items.map((i) => BottomNavigationBarItem(icon: Icon(i.icon), activeIcon: Icon(i.activeIcon), label: i.label)).toList(),
    );
  }

  Widget _buildNavigationRail(BuildContext context, bool showUsuarios, bool showEventos, bool showLugares) {
    final items = _buildItems(showUsuarios, showEventos, showLugares);
    final location = GoRouterState.of(context).uri.path;
    int idx = 0;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) idx = i;
    }
    return NavigationRail(
      selectedIndex: idx,
      onDestinationSelected: (i) => context.go(items[i].path),
      labelType: NavigationRailLabelType.selected,
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor, size: 24),
      unselectedIconTheme: IconThemeData(color: Colors.grey.shade600, size: 24),
      selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      destinations: items.map((i) => NavigationRailDestination(icon: Icon(i.icon), selectedIcon: Icon(i.activeIcon), label: Text(i.label))).toList(),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem(this.path, this.icon, this.activeIcon, this.label);
}
