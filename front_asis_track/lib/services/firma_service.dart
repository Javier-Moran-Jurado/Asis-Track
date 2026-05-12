/// Servicio mock para la captura y envío de firma digital.
///
/// Todos los métodos contienen comentarios indicando dónde conectar el backend
/// real cuando los endpoints estén disponibles.
class FirmaService {
  // ══════════════════════════════════════════════════════════════════════════
  // SELECCIÓN DE IMAGEN
  // ══════════════════════════════════════════════════════════════════════════

  /// Simula la selección de una imagen desde galería o cámara.
  ///
  /// TODO: Integrar image_picker para selección real.
  ///   - Agregar dependencia en pubspec.yaml: image_picker: ^1.0.0
  ///   - Usar ImagePicker().pickImage(source: ImageSource.gallery)
  static Future<String?> seleccionarImagen() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // TODO: Reemplazar con image_picker real
    return 'firma_imagen.jpg';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENVÍO DE FIRMA
  // ══════════════════════════════════════════════════════════════════════════

  /// Envía la firma digital al backend.
  ///
  /// TODO: Conectar con el endpoint real del backend.
  ///   POST /api/v1/firmas
  ///   Body: multipart/form-data con el archivo PNG/JPEG
  ///   Headers: Authorization: Bearer {access_token}
  static Future<bool> enviarFirma({
    required String archivo,
    String? tipo, // 'imagen' o 'dibujo'
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // TODO: Reemplazar con llamada HTTP real
    // final uri = Uri.parse('$_baseUrl/api/v1/firmas');
    // final request = http.MultipartRequest('POST', uri);
    // request.headers['Authorization'] = 'Bearer $accessToken';
    // request.files.add(await http.MultipartFile.fromPath('firma', archivo));
    // final response = await request.send();

    return true;
  }
}
