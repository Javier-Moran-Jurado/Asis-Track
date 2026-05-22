import 'package:flutter/foundation.dart';
import '../models/justificacion_model.dart';
import '../services/justificacion_service.dart';

/// Provider que centraliza el estado del estudiante autenticado.
///
/// Expone:
///   • Lista de justificaciones personales.
///   • Indicadores de carga y error.
///   • Conteo de justificaciones pendientes.
///
/// Las vistas de estudiante deben consumir este provider en lugar de
/// llamar directamente a los servicios.
class StudentProvider extends ChangeNotifier {
  // ──────────────────────────────────────────────────────────────────────────
  // Estado interno
  // ──────────────────────────────────────────────────────────────────────────
  List<JustificacionModel> _justificaciones = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ──────────────────────────────────────────────────────────────────────────
  // Getters públicos
  // ──────────────────────────────────────────────────────────────────────────
  List<JustificacionModel> get justificaciones => _justificaciones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendientesCount => _justificaciones
      .where((j) => j.estado.toUpperCase() == 'PENDIENTE')
      .length;

  // ══════════════════════════════════════════════════════════════════════════
  // CARGAR JUSTIFICACIONES DEL ESTUDIANTE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> cargarJustificaciones(int codigoEstudiante) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await JustificacionService.obtenerPorEstudiante(codigoEstudiante);
      _justificaciones = raw.map((e) => JustificacionModel.fromJson(e)).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOLICITAR NUEVA JUSTIFICACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> solicitarJustificacion({
    required int eventoId,
    required int codigoEstudiante,
    required String motivo,
    String? documentoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await JustificacionService.solicitarJustificacion(
        eventoId: eventoId,
        codigoEstudiante: codigoEstudiante,
        motivo: motivo,
        documentoUrl: documentoUrl,
      );
      // Refresca la lista tras enviar correctamente
      await cargarJustificaciones(codigoEstudiante);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> refrescar(int codigoEstudiante) =>
      cargarJustificaciones(codigoEstudiante);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
