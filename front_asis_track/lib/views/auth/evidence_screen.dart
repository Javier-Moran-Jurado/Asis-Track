import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';

/// Pantalla de evidencia de autenticación JWT.
///
/// Muestra de forma visual:
///   1. Datos del usuario leídos desde SharedPreferences.
///   2. Estado de los tokens leídos desde FlutterSecureStorage.
///   3. Representación del flujo de autenticación (endpoint, request/response
///      y dónde se almacena cada dato).
///   4. Botón de cierre de sesión.
class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  // ──────────────────────────────────────────────────────────────────────────
  // Estado cargado asíncronamente
  // ──────────────────────────────────────────────────────────────────────────
  bool _loading = true;

  // Datos desde SharedPreferences
  String _nombre = '';
  String _correo = '';
  String _codigo = '';
  String _rol = '';

  // Estado de tokens desde SecureStorage
  bool _hasAccessToken = false;
  bool _hasRefreshToken = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga en paralelo los datos de SharedPreferences y SecureStorage.
  Future<void> _loadData() async {
    // Ejecutar en paralelo para minimizar el tiempo de espera.
    final userFuture = AuthService.getUserFromPrefs();
    final accessFuture = AuthService.getAccessToken();
    final refreshFuture = AuthService.getRefreshToken();

    final user = await userFuture;
    final accessToken = await accessFuture;
    final refreshToken = await refreshFuture;

    if (!mounted) return;
    setState(() {
      if (user != null) {
        _nombre = user.nombreCompleto;
        _correo = user.correo;
        _codigo = user.codigo;
        _rol = user.rol;
      }
      _hasAccessToken = accessToken != null && accessToken.isNotEmpty;
      _hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evidencia de Autenticación',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppTheme.gray50,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      icon: Icons.person_outline,
                      iconColor: AppTheme.primaryColor,
                      title: 'Perfil de usuario',
                      subtitle: 'Fuente: SharedPreferences',
                      child: _UserProfileContent(
                        nombre: _nombre,
                        correo: _correo,
                        codigo: _codigo,
                        rol: _rol,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.lock_outline,
                      iconColor: AppTheme.secondaryColor,
                      title: 'Estado de sesión',
                      subtitle: 'Fuente: FlutterSecureStorage',
                      child: _TokenStatusContent(
                        hasAccessToken: _hasAccessToken,
                        hasRefreshToken: _hasRefreshToken,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.api_outlined,
                      iconColor: AppTheme.warningColor,
                      title: 'Flujo de autenticación',
                      subtitle:
                          'Cómo se consume el API y se almacena la respuesta',
                      child: const _AuthFlowContent(),
                    ),
                    const SizedBox(height: 24),
                    _LogoutButton(onLogout: _logout),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECCIÓN: Tarjeta genérica
// ════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.gray900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECCIÓN 1: Perfil de usuario (SharedPreferences)
// ════════════════════════════════════════════════════════════════════════════

class _UserProfileContent extends StatelessWidget {
  final String nombre;
  final String correo;
  final String codigo;
  final String rol;

  const _UserProfileContent({
    required this.nombre,
    required this.correo,
    required this.codigo,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DataRow(label: 'Nombre', value: nombre.isEmpty ? '—' : nombre),
        _DataRow(label: 'Correo', value: correo.isEmpty ? '—' : correo),
        _DataRow(label: 'Código', value: codigo.isEmpty ? '—' : codigo),
        _DataRow(label: 'Rol', value: rol.isEmpty ? '—' : rol),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.storage, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Almacenado en SharedPreferences — datos NO sensibles',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECCIÓN 2: Estado de tokens (SecureStorage)
// ════════════════════════════════════════════════════════════════════════════

class _TokenStatusContent extends StatelessWidget {
  final bool hasAccessToken;
  final bool hasRefreshToken;

  const _TokenStatusContent({
    required this.hasAccessToken,
    required this.hasRefreshToken,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TokenRow(
          label: 'access_token',
          present: hasAccessToken,
        ),
        const SizedBox(height: 8),
        _TokenRow(
          label: 'refresh_token',
          present: hasRefreshToken,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.lock, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Almacenado en FlutterSecureStorage — datos SENSIBLES',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  final String label;
  final bool present;

  const _TokenRow({required this.label, required this.present});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppTheme.gray900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: present
                ? AppTheme.secondaryColor.withAlpha(25)
                : AppTheme.errorColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                present ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: present ? AppTheme.secondaryColor : AppTheme.errorColor,
              ),
              const SizedBox(width: 4),
              Text(
                present ? 'Token presente' : 'Sin token',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      present ? AppTheme.secondaryColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECCIÓN 3: Flujo de autenticación
// ════════════════════════════════════════════════════════════════════════════

class _AuthFlowContent extends StatelessWidget {
  const _AuthFlowContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Paso 1: Request ──────────────────────────────────────────────
        _FlowStep(
          stepNumber: '1',
          stepColor: AppTheme.primaryColor,
          title: 'Petición al API',
          child: _CodeBlock(
            lines: const [
              'POST /api/v1/auth/login',
              '',
              'Headers:',
              '  Content-Type: application/json',
              '',
              'Body:',
              '  {',
              '    "codigo": <Long>,',
              '    "contrasena": "••••••••"',
              '  }',
            ],
          ),
        ),
        _FlowArrow(),

        // ── Paso 2: Response ──────────────────────────────────────────────
        _FlowStep(
          stepNumber: '2',
          stepColor: AppTheme.warningColor,
          title: 'Respuesta del servidor',
          child: _CodeBlock(
            lines: const [
              'HTTP 200 OK',
              '',
              '{',
              '  "access_token":  "eyJ...",',
              '  "refresh_token": "eyJ..."',
              '}',
            ],
          ),
        ),
        _FlowArrow(),

        // ── Paso 3: Decodificación JWT ────────────────────────────────────
        _FlowStep(
          stepNumber: '3',
          stepColor: AppTheme.primaryColor,
          title: 'Decodificación del JWT (sin librería)',
          child: _CodeBlock(
            lines: const [
              '// Claims extraídos del payload:',
              'jti             → codigo del usuario',
              'nombre_completo → nombre del usuario',
              'rol             → rol del usuario',
              '',
              '// Llamada adicional:',
              'GET /api/v1/usuario-service/usuarios/{codigo}',
              '  → correo del usuario',
            ],
          ),
        ),
        _FlowArrow(),

        // ── Paso 4: Almacenamiento ────────────────────────────────────────
        _FlowStep(
          stepNumber: '4',
          stepColor: AppTheme.secondaryColor,
          title: 'Almacenamiento segregado',
          child: Column(
            children: [
              _StorageBlock(
                icon: Icons.lock,
                color: AppTheme.errorColor,
                label: 'FlutterSecureStorage  (datos SENSIBLES)',
                items: const ['access_token', 'refresh_token'],
              ),
              const SizedBox(height: 8),
              _StorageBlock(
                icon: Icons.storage,
                color: AppTheme.primaryColor,
                label: 'SharedPreferences  (datos NO sensibles)',
                items: const [
                  'user_nombre_completo',
                  'user_correo',
                  'user_codigo',
                  'user_rol',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String stepNumber;
  final Color stepColor;
  final String title;
  final Widget child;

  const _FlowStep({
    required this.stepNumber,
    required this.stepColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: stepColor,
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: Icon(Icons.arrow_downward, size: 18, color: Colors.grey.shade400),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final List<String> lines;

  const _CodeBlock({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Text(
                line,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFFCDD6F4),
                  height: 1.6,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StorageBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final List<String> items;

  const _StorageBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                children: [
                  const Text('•  ',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    item,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppTheme.gray900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGET REUTILIZABLES
// ════════════════════════════════════════════════════════════════════════════

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOTÓN DE CIERRE DE SESIÓN
// ════════════════════════════════════════════════════════════════════════════

class _LogoutButton extends StatefulWidget {
  final Future<void> Function() onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loading = false;

  Future<void> _handleLogout() async {
    setState(() => _loading = true);
    await widget.onLogout();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _handleLogout,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.logout, size: 20),
      label: Text(
        _loading ? 'Cerrando sesión...' : 'Cerrar sesión',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
