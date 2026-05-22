/// Helpers de rol para determinar los permisos del usuario autenticado.
///
/// El rol proviene del campo `rol` del JWT, decodificado en [AuthProvider].
/// Valores conocidos del backend: 'Administrador', 'Docente', 'Monitor',
/// 'Estudiante', 'Decano', 'Coordinador'
/// 'Invitado' es un rol local sin acceso al backend.
class RoleService {
  static bool _isGuest(String rol) => rol.toLowerCase() == 'invitado';

  /// Devuelve `true` si el rol puede generar QR (Docente, Monitor o Administrador).
  static bool canGenerateQr(String rol) {
    if (_isGuest(rol)) return false;
    final r = rol.toLowerCase();
    return r == 'docente' || r == 'monitor' || r == 'administrador';
  }

  /// Devuelve `true` si el rol puede validar (aprobar/rechazar) justificaciones.
  /// Solo Decano y Administrador tienen este permiso.
  static bool canValidateJustificacion(String rol) {
    if (_isGuest(rol)) return false;
    final r = rol.toLowerCase();
    return r == 'decano' || r == 'administrador';
  }

  /// Devuelve `true` si el rol puede crear/editar eventos.
  static bool canCreateEvents(String rol) {
    if (_isGuest(rol)) return false;
    final r = rol.toLowerCase();
    return r == 'docente' || r == 'monitor' || r == 'administrador' || r == 'administrativo' || r == 'decano';
  }

  /// Devuelve `true` si el rol puede crear nuevos usuarios.
  /// Solo Administrador y Administrativo tienen este permiso.
  static bool canCreateUsers(String rol) {
    if (_isGuest(rol)) return false;
    final r = rol.toLowerCase();
    return r == 'administrador' || r == 'administrativo';
  }

  /// Devuelve `true` si el rol puede crear planillas.
  static bool canCreatePlanillas(String rol) {
    if (_isGuest(rol)) return false;
    return true;
  }

  /// Devuelve `true` si el rol puede eliminar planillas.
  static bool canDeletePlanillas(String rol) {
    if (_isGuest(rol)) return false;
    return true;
  }

  /// Devuelve `true` si el rol es estudiante.
  static bool isStudent(String rol) {
    if (_isGuest(rol)) return false;
    return rol.toLowerCase() == 'estudiante';
  }

  /// Etiqueta legible para mostrar en la UI.
  static String displayLabel(String rol) {
    if (rol.isEmpty) return 'Sin rol';
    if (_isGuest(rol)) return 'Invitado';
    return rol[0].toUpperCase() + rol.substring(1).toLowerCase();
  }
}
