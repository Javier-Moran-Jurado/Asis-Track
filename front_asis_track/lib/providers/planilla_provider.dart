// lib/providers/planilla_provider.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planilla.dart';
import '../models/planilla_digital.dart';
import '../models/student_record.dart';
import '../services/planilla_service.dart';
import '../services/campo_service.dart';
import '../services/fila_service.dart';

class PlanillaProvider extends ChangeNotifier {
  List<Planilla> _planillas = [];
  bool _cargandoLista = false;
  String? _errorLista;

  List<Planilla> get planillas => _planillas;
  bool get cargandoLista => _cargandoLista;
  String? get errorLista => _errorLista;

  List<EventoPlanilla> _eventos = [];
  bool _cargandoEventos = false;
  EventoPlanilla? _eventoSeleccionado;
  int? _planillaActualId;
  List<CampoPreviewModel> _campos = [];
  bool _creandoPlanilla = false;

  List<EventoPlanilla> get eventos => _eventos;
  bool get cargandoEventos => _cargandoEventos;
  EventoPlanilla? get eventoSeleccionado => _eventoSeleccionado;
  int? get planillaActualId => _planillaActualId;
  List<CampoPreviewModel> get campos => List.unmodifiable(_campos);
  bool get creandoPlanilla => _creandoPlanilla;

  Future<void> cargarPlanillas() async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();
    try {
      _planillas = await PlanillaService.obtenerPlanillas();
    } catch (e) {
      _errorLista = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargandoLista = false;
      notifyListeners();
    }
  }

  Future<void> eliminarPlanilla(int id) async {
    await PlanillaService.eliminarPlanilla(id);
    _planillas.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> cargarEventos() async {
    _cargandoEventos = true;
    notifyListeners();
    try {
      _eventos = await PlanillaService.obtenerEventos();
    } catch (_) {}
    _cargandoEventos = false;
    notifyListeners();
  }

  void seleccionarEvento(EventoPlanilla? evento) {
    _eventoSeleccionado = evento;
    notifyListeners();
  }

  Future<void> cargarPlanillaExistente(int id) async {
    _cargandoEventos = true;
    notifyListeners();
    try {
      final planilla = await PlanillaService.obtenerPlanilla(id);
      _planillaActualId = planilla.id;
      _campos = planilla.campos ?? [];
      _eventos = await PlanillaService.obtenerEventos();
      if (planilla.eventoId != null) {
        _eventoSeleccionado = _eventos.where((e) => e.id == planilla.eventoId).firstOrNull;
      }
    } catch (_) {}
    _cargandoEventos = false;
    notifyListeners();
  }

  Future<void> crearPlanillaBorrador() async {
    if (_eventoSeleccionado == null) throw Exception('Selecciona un evento');
    _creandoPlanilla = true;
    notifyListeners();
    try {
      final planilla = await PlanillaService.crearPlanilla({
        'eventoId': _eventoSeleccionado!.id,
        'origenId': 1,
      });
      _planillaActualId = planilla.id;
    } finally {
      _creandoPlanilla = false;
      notifyListeners();
    }
  }

  Future<void> cargarCampos() async {
    if (_planillaActualId == null) return;
    try {
      _campos = await CampoService.obtenerCampos(_planillaActualId!);
      notifyListeners();
    } catch (_) {}
  }

  void agregarCampoLocal(CampoPreviewModel campo) {
    _campos.add(campo);
    notifyListeners();
  }

  void actualizarCampoLocal(CampoPreviewModel campo) {
    final idx = _campos.indexWhere((c) => c.id == campo.id);
    if (idx >= 0) {
      _campos[idx] = campo;
      notifyListeners();
    }
  }

  Future<void> eliminarCampo(int campoId) async {
    await CampoService.eliminarCampo(campoId);
    _campos.removeWhere((c) => c.id == campoId);
    notifyListeners();
  }

  Future<void> confirmarPlanilla() async {
    if (_planillaActualId == null) return;
    await PlanillaService.actualizarPlanilla(_planillaActualId!, {
      'origenId': 1,
      'eventoId': _eventoSeleccionado?.id,
    });
  }

  Future<void> cancelarCreacion() async {
    if (_planillaActualId != null) {
      try {
        await PlanillaService.eliminarPlanilla(_planillaActualId!);
      } catch (_) {}
    }
    resetFormulario();
  }

  void resetFormulario() {
    _eventoSeleccionado = null;
    _planillaActualId = null;
    _campos = [];
    _creandoPlanilla = false;
    notifyListeners();
  }
}

enum ImageMode { panZoom, cropSignature, referenceOnly }

class PlanillaDigitalState {
  final PlanillaDigital? planilla;
  final ImageMode mode;
  final Rect? cropSelection;
  final int? targetRecordIndex;

  const PlanillaDigitalState({
    this.planilla,
    this.mode = ImageMode.panZoom,
    this.cropSelection,
    this.targetRecordIndex,
  });

  PlanillaDigitalState copyWith({
    PlanillaDigital? planilla,
    ImageMode? mode,
    Rect? cropSelection,
    int? targetRecordIndex,
  }) {
    return PlanillaDigitalState(
      planilla: planilla ?? this.planilla,
      mode: mode ?? this.mode,
      cropSelection: cropSelection,
      targetRecordIndex: targetRecordIndex ?? this.targetRecordIndex,
    );
  }
}

class PlanillaNotifier extends StateNotifier<PlanillaDigitalState> {
  final TransformationController transformationController =
      TransformationController();

  PlanillaNotifier() : super(const PlanillaDigitalState());

  void setPlanilla(PlanillaDigital planilla) {
    state = PlanillaDigitalState(
      planilla: planilla,
      mode: ImageMode.panZoom,
      cropSelection: null,
      targetRecordIndex: null,
    );
  }

  void setMode(ImageMode mode) {
    state = state.copyWith(
      mode: mode,
      cropSelection: mode == ImageMode.cropSignature ? state.cropSelection : null,
      targetRecordIndex:
          mode == ImageMode.cropSignature ? state.targetRecordIndex : null,
    );
  }

  void setCropSelection(Rect? rect) {
    state = state.copyWith(cropSelection: rect);
  }

  void setTargetRecord(int? index) {
    state = state.copyWith(targetRecordIndex: index);
  }

  Future<void> confirmCrop(Uint8List croppedBytes, int recordIndex) async {
    final planilla = state.planilla;
    if (planilla == null) return;
    if (recordIndex < 0 || recordIndex >= planilla.records.length) return;

    final oldRecord = planilla.records[recordIndex];
    final updatedRecord = oldRecord
        .copyWith(signatureBytes: croppedBytes, signatureSource: null);
    final updatedRecords = [...planilla.records];
    updatedRecords[recordIndex] = updatedRecord;
    state = state.copyWith(
      planilla: planilla.copyWith(records: updatedRecords),
      cropSelection: null,
      targetRecordIndex: null,
      mode: ImageMode.panZoom,
    );

    final filaId = updatedRecord.filaId;
    final sigField = planilla.fieldDefs
        .where((f) => f.type == 'signature_file')
        .firstOrNull;
    final sigCampoId = sigField?.originalCampoId;
    if (filaId == null || sigCampoId == null) return;
    try {
      await _uploadSignature(filaId, sigCampoId, croppedBytes);
    } catch (e) {
      state = state.copyWith(
        planilla: planilla.copyWith(records: [
          for (int i = 0; i < planilla.records.length; i++)
            if (i == recordIndex) oldRecord else planilla.records[i],
        ]),
      );
      rethrow;
    }
  }

  Future<void> _uploadSignature(int filaId, int campoId, Uint8List bytes) async {
    await FilaService.subirFirma(filaId, campoId, bytes, filename: 'firma.png');
  }

  void updateRecord(int index, StudentRecord updated) {
    final planilla = state.planilla;
    if (planilla == null) return;
    if (index < 0 || index >= planilla.records.length) return;

    final updatedRecords = [...planilla.records];
    updatedRecords[index] = updated;
    state = state.copyWith(planilla: planilla.copyWith(records: updatedRecords));
  }

  Future<void> savePlanilla() async {
    final planilla = state.planilla;
    if (planilla == null) return;
    state = state.copyWith(planilla: planilla.copyWith(isSaved: true));
  }

  void resetTransformForImage(Size viewportSize) {
    final planilla = state.planilla;
    if (planilla == null) return;
    final imgW = planilla.referenceImage.width.toDouble();
    final imgH = planilla.referenceImage.height.toDouble();
    if (imgW == 0 || imgH == 0) return;

    final scaleX = viewportSize.width / imgW;
    final scaleY = viewportSize.height / imgH;
    final fitScale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (viewportSize.width - imgW * fitScale) / 2;
    final dy = (viewportSize.height - imgH * fitScale) / 2;

    transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(fitScale);
  }

  Rect clampToImage(Rect rect) {
    final planilla = state.planilla;
    if (planilla == null) return rect;
    final maxW = planilla.referenceImage.width.toDouble();
    final maxH = planilla.referenceImage.height.toDouble();

    final left = rect.left.clamp(0.0, maxW);
    final right = rect.right.clamp(0.0, maxW);
    final top = rect.top.clamp(0.0, maxH);
    final bottom = rect.bottom.clamp(0.0, maxH);

    return Rect.fromLTRB(left, top, right, bottom);
  }
}

final planillaProvider =
    StateNotifierProvider<PlanillaNotifier, PlanillaDigitalState>(
  (ref) => PlanillaNotifier(),
);

final savedPlanillasProvider =
    StateNotifierProvider<SavesPlanillasNotifier, List<PlanillaDigital>>(
  (ref) => SavesPlanillasNotifier(),
);

class SavesPlanillasNotifier extends StateNotifier<List<PlanillaDigital>> {
  SavesPlanillasNotifier() : super([]);

  void save(PlanillaDigital planilla) {
    state = [...state, planilla.copyWith(isSaved: true)];
  }

  void remove(String eventId) {
    state = state.where((p) => p.eventId != eventId).toList();
  }
}
