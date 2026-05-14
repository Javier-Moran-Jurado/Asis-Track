import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/role_service.dart';
import '../../themes/app_theme.dart';

import '../../services/user_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _fullProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfilCompleto();
  }

  Future<void> _cargarPerfilCompleto() async {
    try {
      final auth = context.read<AuthProvider>();
      final codigo = auth.currentUser?.codigo;
      if (codigo == null || codigo.isEmpty) {
        throw Exception("No hay código de usuario disponible.");
      }

      final profile = await UserService.getUserById(codigo);
      if (mounted) {
        setState(() {
          _fullProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // Default values from AuthProvider (JWT)
    final baseNombre = user?.nombreCompleto ?? '—';
    final baseCorreo = user?.correo ?? '—';
    final baseCodigo = user?.codigo ?? '—';
    final rol = user?.rol ?? '';

    // Complete values from backend
    final nombre = _fullProfile?['nombreCompleto'] as String? ?? baseNombre;
    final correo = _fullProfile?['correo'] as String? ?? baseCorreo;
    final codigo = _fullProfile?['codigo']?.toString() ?? baseCodigo;
    final cedula = _fullProfile?['cedula']?.toString() ?? '—';
    final telefono = _fullProfile?['telefono']?.toString() ?? '—';

    // Iniciales para el avatar
    final partes = nombre.trim().split(' ');
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : nombre.isNotEmpty
            ? nombre[0].toUpperCase()
            : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/icon/logo_asis_track.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'Perfil',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Error cargando perfil completo:\n$_error',
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // ── Avatar ──────────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          iniciales,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Nombre ───────────────────────────────────────────────────
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correo,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // ── Badge de Rol ────────────────────────────────────────────
                    _RolBadge(rol: rol),

                    const SizedBox(height: 32),

                    // ── Tarjetas de info ────────────────────────────────────────
                    _InfoCard(
                      icon: Icons.badge_outlined,
                      label: 'Código',
                      value: codigo,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.credit_card_outlined,
                      label: 'Cédula',
                      value: cedula,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: telefono,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: correo,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.school_outlined,
                      label: 'Rol en el sistema',
                      value: RoleService.displayLabel(rol),
                    ),

                    const SizedBox(height: 32),

                    // ── Cerrar sesión ───────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Cerrar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de Rol
// ─────────────────────────────────────────────────────────────────────────────
class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  Color get _color {
    final r = rol.toLowerCase();
    if (r == 'administrador') return const Color(0xFF7C3AED);
    if (r == 'docente') return const Color(0xFF2563EB);
    if (r == 'monitor') return const Color(0xFF0891B2);
    return const Color(0xFF10B981); // estudiante
  }

  IconData get _icon {
    final r = rol.toLowerCase();
    if (r == 'administrador') return Icons.admin_panel_settings;
    if (r == 'docente') return Icons.person_pin;
    if (r == 'monitor') return Icons.supervised_user_circle;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            RoleService.displayLabel(rol),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de información (solo lectura)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

