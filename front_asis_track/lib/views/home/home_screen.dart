import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/historial_asistencia.dart';
import '../../providers/auth_provider.dart';
import '../../services/role_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.currentUser?.nombreCompleto ?? 'Usuario';
    final rol = auth.currentUser?.rol ?? '';
    final esMonitor = rol.toLowerCase() == 'monitor';
    final esEstudiante = rol.toLowerCase() == 'estudiante';

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppBreakpoints.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(nombre, rol),
              const SizedBox(height: 32),
              _buildActionCards(context, esMonitor, esEstudiante),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(String nombre, String rol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido/a, $nombre',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8,
                          color: AppTheme.secondaryColor
                              .withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        RoleService.displayLabel(rol),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '¿Qué necesitas hacer hoy?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTION CARDS GRID
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionCards(
      BuildContext context, bool esMonitor, bool esEstudiante) {
    final cards = <_ActionCardData>[
      _ActionCardData(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Registrar asistencia',
        subtitle: 'Escanea un código QR o genera uno nuevo',
        color: AppTheme.primaryColor,
        onTap: () => context.push('/asistencia'),
      ),
      _ActionCardData(
        icon: Icons.history_outlined,
        title: 'Ver historial',
        subtitle: 'Consulta tus registros de asistencia',
        color: const Color(0xFF7C3AED),
        onTap: () => context.push('/historial'),
      ),
      // Solo Estudiante: solicitar justificación
      if (esEstudiante)
        _ActionCardData(
          icon: Icons.description_outlined,
          title: 'Solicitar justificación',
          subtitle: 'Justifica una inasistencia con evidencia',
          color: AppTheme.warningColor,
          onTap: () {
            final mock = HistorialAsistencia(
              id: 'home_${DateTime.now().millisecondsSinceEpoch}',
              fecha: DateTime.now(),
              materia: 'Selecciona la materia',
              tipoEvento: 'Clase',
              asistio: false,
              docente: 'Por definir',
              ubicacion: 'Por definir',
            );
            context.push('/justificaciones/nueva', extra: mock);
          },
        ),
      // No Estudiante: ver justificaciones + planillas + dashboard
      if (!esEstudiante) ...[
        _ActionCardData(
          icon: Icons.fact_check_outlined,
          title: 'Ver justificaciones',
          subtitle: 'Revisa y valida solicitudes pendientes',
          color: AppTheme.secondaryColor,
          onTap: () => context.push('/justificaciones'),
        ),
        _ActionCardData(
          icon: Icons.assignment_outlined,
          title: 'Planillas',
          subtitle: 'Gestiona planillas de asistencia',
          color: const Color(0xFFF59E0B),
          onTap: () => context.push('/planillas'),
        ),
        if (!esMonitor)
          _ActionCardData(
            icon: Icons.bar_chart_outlined,
            title: 'Dashboard',
            subtitle: 'Estadísticas y gráficos de planillas',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/dashboard'),
          ),
      ],
    ];

    final columns = AppBreakpoints.gridColumns(context);
    final spacing = 16.0;
    final padding = AppBreakpoints.responsivePadding(context);
    final availableWidth =
        MediaQuery.of(context).size.width - padding.horizontal;
    final cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;
    final cardHeight = cardWidth * 0.9;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: cards
          .map((data) => SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildCard(context, data),
              ))
          .toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SINGLE CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCard(BuildContext context, _ActionCardData data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: data.color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,
      title: const Text(
        'AsisTrack',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }
}

class _ActionCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
