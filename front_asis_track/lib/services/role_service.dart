/// Helpers de rol para determinar los permisos del usuario autenticado.
///
/// El rol proviene del campo `rol` del JWT, decodificado en [AuthProvider].
/// Valores conocidos del backend: 'Administrador', 'Docente', 'Monitor',
/// 'Estudiante', 'Decano', 'Coordinador'
class RoleService {
  /// Devuelve `true` si el rol puede generar QR (Docente, Monitor o Administrador).
  static bool canGenerateQr(String rol) {
    final r = rol.toLowerCase();
    return r == 'docente' || r == 'monitor' || r == 'administrador';
  }

  /// Devuelve `true` si el rol puede validar (aprobar/rechazar) justificaciones.
  /// Solo Decano y Administrador tienen este permiso.
  static bool canValidateJustificacion(String rol) {
    final r = rol.toLowerCase();
    return r == 'decano' || r == 'administrador';
  }

  /// Devuelve `true` si el rol puede crear/editar eventos.
  static bool canCreateEvents(String rol) {
    final r = rol.toLowerCase();
    return r == 'docente' || r == 'monitor' || r == 'administrador' || r == 'administrativo' || r == 'decano';
  }

  /// Devuelve `true` si el rol puede crear nuevos usuarios.
  /// Solo Administrador y Administrativo tienen este permiso.
  static bool canCreateUsers(String rol) {
    final r = rol.toLowerCase();
    return r == 'administrador' || r == 'administrativo';
  }

  /// Etiqueta legible para mostrar en la UI.
  static String displayLabel(String rol) {
    if (rol.isEmpty) return 'Sin rol';
    return rol[0].toUpperCase() + rol.substring(1).toLowerCase();
  }
}
