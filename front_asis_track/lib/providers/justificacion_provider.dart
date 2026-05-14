import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Estados del formulario de justificación.
enum JustificacionFormStatus {
  initial,
  loading,
  success,
  error,
}

/// Tipo de firma: dibujada a mano o imagen subida.
enum TipoFirma { dibujo, imagen }

/// Provider que maneja el estado del formulario de justificación.
///
/// Centraliza:
///   • Los campos del formulario (motivo, descripción, archivo).
///   • El estado de la firma (dibujada o no).
///   • El flujo de envío (cargando, éxito, error).
class JustificacionProvider extends ChangeNotifier {
  // ──────────────────────────────────────────────────────────────────────────
  // Estado del formulario
  // ──────────────────────────────────────────────────────────────────────────
  JustificacionFormStatus _status = JustificacionFormStatus.initial;
  String? _errorMessage;

  String? _motivo;
  String? _descripcion;
  String? _archivo;
  TipoFirma _tipoFirma = TipoFirma.dibujo;
  String? _imagenFirma;
  List<List<Offset>> _firmas = [];

  // ──────────────────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────────────────
  JustificacionFormStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get motivo => _motivo;
  String? get descripcion => _descripcion;
  String? get archivo => _archivo;
  TipoFirma get tipoFirma => _tipoFirma;
  String? get imagenFirma => _imagenFirma;
  List<List<Offset>> get firmas => _firmas;

  bool get isLoading => _status == JustificacionFormStatus.loading;
  bool get isSuccess => _status == JustificacionFormStatus.success;
  bool get hasFirma => _firmas.isNotEmpty || _imagenFirma != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Métodos del formulario
  // ──────────────────────────────────────────────────────────────────────────

  void setMotivo(String? value) {
    _motivo = value;
    notifyListeners();
  }

  void setDescripcion(String? value) {
    _descripcion = value;
    notifyListeners();
  }

  void setArchivo(String? value) {
    _archivo = value;
    notifyListeners();
  }

  void limpiarArchivo() {
    _archivo = null;
    notifyListeners();
  }

  // ── Tipo de firma ────────────────────────────────────────────────────────

  void setTipoFirma(TipoFirma tipo) {
    _tipoFirma = tipo;
    // Limpiar el tipo anterior
    if (tipo == TipoFirma.dibujo) {
      _imagenFirma = null;
    } else {
      _firmas = [];
    }
    notifyListeners();
  }

  void setImagenFirma(String? value) {
    _imagenFirma = value;
    notifyListeners();
  }

  // ── Firma ────────────────────────────────────────────────────────────────

  void agregarFirma(Offset punto) {
    if (_firmas.isEmpty) {
      _firmas.add([]);
    }
    _firmas.last = [..._firmas.last, punto];
    notifyListeners();
  }

  void nuevaLineaFirma() {
    if (_firmas.isNotEmpty && _firmas.last.isNotEmpty) {
      _firmas.add([]);
      notifyListeners();
    }
  }

  void limpiarFirma() {
    _firmas = [];
    notifyListeners();
  }

  // ── Validación ───────────────────────────────────────────────────────────

  bool get isFormValid =>
      _motivo != null &&
      _motivo!.isNotEmpty &&
      _descripcion != null &&
      _descripcion!.trim().isNotEmpty;

  // ── Envío ────────────────────────────────────────────────────────────────

  Future<void> enviar({
    required Future<bool> Function({
      required String asistenciaId,
      required String motivo,
      required String descripcion,
      String? archivo,
      String? firma,
    }) onSubmit,
    required String asistenciaId,
  }) async {
    if (!isFormValid) return;

    _status = JustificacionFormStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await onSubmit(
        asistenciaId: asistenciaId,
        motivo: _motivo!,
        descripcion: _descripcion!,
        archivo: _archivo,
        firma: _imagenFirma ?? (_firmas.isNotEmpty ? 'firma_digital' : null),
      );

      if (success) {
        _status = JustificacionFormStatus.success;
      } else {
        _status = JustificacionFormStatus.error;
        _errorMessage = 'No se pudo enviar la justificación.';
      }
    } catch (e) {
      _status = JustificacionFormStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  void limpiarEstado() {
    _status = JustificacionFormStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
