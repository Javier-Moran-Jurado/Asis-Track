/// Servicio mock para la gestión de justificaciones.
///
/// Todos los métodos contienen comentarios indicando dónde conectar el backend
/// real cuando los endpoints estén disponibles.
class JustificacionService {
  // ══════════════════════════════════════════════════════════════════════════
  // ENVÍO DE JUSTIFICACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  /// Envía una solicitud de justificación.
  ///
  /// TODO: Conectar con el endpoint real del backend.
  ///   POST /api/v1/justificaciones
  ///   Body: {
  ///     "asistenciaId": String,
  ///     "motivo": String,
  ///     "descripcion": String,
  ///     "archivo": String? (base64 o URL),
  ///     "firma": String? (base64)
  ///   }
  ///   Headers: Authorization: Bearer {access_token}
  static Future<bool> enviarJustificacion({
    required String asistenciaId,
    required String motivo,
    required String descripcion,
    String? archivo,
    String? firma,
  }) async {
    // Simula latencia de red
    await Future<void>.delayed(const Duration(seconds: 2));

    // TODO: Reemplazar con llamada HTTP real
    // final uri = Uri.parse('$_baseUrl/api/v1/justificaciones');
    // final response = await http.post(
    //   uri,
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $accessToken',
    //   },
    //   body: jsonEncode({...}),
    // );

    // Siempre retorna éxito en mock
    return true;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELECCIÓN DE ARCHIVO
  // ══════════════════════════════════════════════════════════════════════════

  /// Simula la selección de un archivo desde galería, cámara o almacenamiento.
  ///
  /// TODO: Integrar file_picker o image_picker para selección real.
  ///   - Agregar dependencia en pubspec.yaml: file_picker: ^8.0.0
  ///   - Usar FilePicker.platform.pickFiles() para seleccionar
  ///   - Comprimir imagen si es necesario
  ///   - Convertir a base64 para enviar al backend
  static Future<String?> seleccionarArchivo() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // TODO: Reemplazar con file_picker real
    // final result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    // );
    // if (result != null && result.files.isNotEmpty) {
    //   return result.files.single.name;
    // }

    return 'documento_respaldo.pdf';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELECCIÓN DE IMAGEN DE FIRMA
  // ══════════════════════════════════════════════════════════════════════════

  /// Simula la selección de una imagen de firma desde galería o cámara.
  ///
  /// TODO: Integrar image_picker para selección real.
  ///   - Agregar dependencia en pubspec.yaml: image_picker: ^1.0.0
  ///   - Usar ImagePicker().pickImage(source: ImageSource.gallery)
  static Future<String?> seleccionarImagenFirma() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // TODO: Reemplazar con image_picker real
    return 'firma_usuario.jpg';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENCIÓN DE JUSTIFICACIONES (listado)
  // ══════════════════════════════════════════════════════════════════════════

  /// Obtiene el listado de justificaciones del usuario.
  ///
  /// TODO: Conectar con el endpoint real del backend.
  ///   GET /api/v1/justificaciones
  ///   Headers: Authorization: Bearer {access_token}
  static Future<List<Map<String, dynamic>>> obtenerJustificaciones() async {
    await Future<void>.delayed(const Duration(seconds: 1));

    // TODO: Reemplazar con llamada HTTP real
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALIDACIÓN DE JUSTIFICACIONES (aprobar / rechazar)
  // ══════════════════════════════════════════════════════════════════════════

  /// Aprueba o rechaza una justificación.
  ///
  /// Solo disponible para roles Decano y Administrador.
  ///
  /// TODO: Conectar con el endpoint real del backend.
  ///   PUT /api/v1/justificaciones/{id}/validar
  ///   Body: { "aprobada": bool, "comentario": String? }
  ///   Headers: Authorization: Bearer {access_token}
  static Future<bool> validarJustificacion({
    required String justificacionId,
    required bool aprobada,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // TODO: Reemplazar con llamada HTTP real
    return true;
  }
}
