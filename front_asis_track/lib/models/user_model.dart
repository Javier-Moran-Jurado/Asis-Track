/// Modelo que representa al usuario autenticado.
/// Mapea la respuesta del endpoint:
///   GET /api/v1/usuario-service/usuarios/{id}
///   → { "usuario": { "codigo": Long, "nombreCompleto": String, "correo": String, "rol": String, ... } }
class UserModel {
  final String codigo;
  final String nombreCompleto;
  final String correo;
  final String rol;

  const UserModel({
    required this.codigo,
    required this.nombreCompleto,
    required this.correo,
    required this.rol,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Deserialización: el backend puede devolver `codigo` como Long (int) o String.
  // ──────────────────────────────────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      codigo: json['codigo']?.toString() ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Serialización: útil para persistir en SharedPreferences si fuese necesario.
  // ──────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'rol': rol,
      };

  @override
  String toString() =>
      'UserModel(codigo: $codigo, nombreCompleto: $nombreCompleto, '
      'correo: $correo, rol: $rol)';
}
