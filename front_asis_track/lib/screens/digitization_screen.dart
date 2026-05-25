import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/planilla.dart';
import '../models/planilla_digital.dart';
import '../models/planilla_field_def.dart';
import '../models/student_record.dart';
import '../providers/planilla_provider.dart';
import '../services/planilla_service.dart';
import '../themes/app_theme.dart';

class DigitizationScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const DigitizationScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<DigitizationScreen> createState() => _DigitizationScreenState();
}

class _DigitizationScreenState extends ConsumerState<DigitizationScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.camera));
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(
      source: source,
      imageQuality: 85,      // Compresión razonable para reducir tamaño
      maxWidth: 2000,        // Max 2000px de ancho
      maxHeight: 2000,       // Max 2000px de alto
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = img.name;
      _error = null;
    });
    await _digitize();
  }

  /// Redimensiona bytes de imagen si superan el tamaño máximo (para archivos del explorador)
  Future<Uint8List> _compressImageBytes(Uint8List bytes, String filename) async {
    // Para PDF y ZIP no hacemos nada
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf') || lower.endsWith('.zip')) return bytes;

    // Si la imagen es menor a 3MB, la enviamos tal cual
    if (bytes.length < 3 * 1024 * 1024) return bytes;

    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 2000,
        targetHeight: 2000,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {}
    return bytes;
  }

  Future<void> _seleccionarArchivoExplorador() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final compressedBytes = await _compressImageBytes(file.bytes!, file.name);

    if (!mounted) return;
    setState(() {
      _imageBytes = compressedBytes;
      _imageName = file.name;
      _loading = false;
    });
    await _digitize();
  }

  String _inferMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'image/jpeg';
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
  bool _isBase64(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 40) return false;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(cleaned);
  }

  Future<Uint8List?> _decodeSignature(String value) async {
    if (value.isEmpty) return null;
    if (value.startsWith('data:image')) {
      final idx = value.indexOf(',');
      if (idx >= 0) {
        return base64Decode(value.substring(idx + 1));
      }
    }
    if (value.startsWith('http')) {
      try {
        final res = await http.get(Uri.parse(value));
        if (res.statusCode == 200) return res.bodyBytes;
      } catch (_) {}
      return null;
    }
    if (_isBase64(value)) {
      try {
        return base64Decode(value);
      } catch (_) {}
    }
    return null;
  }
  String _buildEstructuraJson(
      List<CampoPreviewModel> campos, List<PlanillaFieldDef> fieldDefs) {
    final encabezados = fieldDefs.map((def) {
      final entry = <String, dynamic>{
        'nombre': def.label,
        'tipo_campo': def.type,
      };
      if (def.type == 'signature_file') {
        entry['instruccion'] =
            'leave value empty, do not read visually';
      }
      return entry;
    }).toList();
    return jsonEncode({'encabezados': encabezados});
  }

  Future<List<StudentRecord>> _mapPlanillaToRecords(
      Planilla planilla, List<PlanillaFieldDef> fieldDefs) async {
    final campos = planilla.campos ?? [];
    final filas = planilla.filas ?? const [];
    final records = <StudentRecord>[];

    for (final fila in filas) {
      final values = <String, String>{};
      Uint8List? signatureBytes;

      for (final def in fieldDefs) {
        final campo = campos.where(
          (c) => _normalize(c.nombreCampo) == _normalize(def.label),
        ).firstOrNull;
        if (campo == null) continue;

        final dato = fila.datos
            .where((d) => d.campoId == campo.id)
            .firstOrNull;

        if (def.type == 'signature_file') {
          final info = dato?.informacion;
          if (info != null && info.isNotEmpty) {
            signatureBytes = await _decodeSignature(info);
          } else {
            signatureBytes = null;
          }
          continue;
        }

        values[def.key] = dato?.informacion ?? '';
      }

      records.add(StudentRecord(
        fields: values,
        signatureBytes: signatureBytes,
        filaId: fila.id,
      ));
    }

    return records;
  }

  List<PlanillaFieldDef> sanitizeFieldDefs(List<PlanillaFieldDef> raw) {
    return raw.map((f) {
      final isFirma = f.key.toLowerCase().contains('firma') ||
          f.label.toLowerCase().contains('firma');
      if (isFirma) {
        return PlanillaFieldDef(
          key: f.key,
          label: f.label,
          type: 'signature_file',
          originalCampoId: f.originalCampoId,
        );
      }
      return f;
    }).toList();
  }

  List<StudentRecord> sanitizeRecords(
      List<StudentRecord> raw, List<PlanillaFieldDef> fieldDefs) {
    final hasSig = fieldDefs.any((f) => f.type == 'signature_file');
    if (!hasSig) return raw;
    return raw.map((r) => r.copyWith(signatureBytes: null, signatureSource: null)).toList();
  }

  List<PlanillaFieldDef> _buildFieldDefs(List<CampoPreviewModel> campos) {
    return campos.map((c) {
      final key = _normalize(c.nombreCampo)
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      return PlanillaFieldDef(
        key: key,
        label: c.nombreCampo,
        type: c.tipoCampo.tipo,
        originalCampoId: c.id,
      );
    }).toList();
  }

  Future<void> _digitize() async {
    if (_imageBytes == null || _imageName == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    int? planillaId;

    try {
      final planilla = await PlanillaService.crearPlanilla({
        'eventoId': int.parse(widget.eventId),
        'origenId': 1,
      });
      planillaId = planilla.id;
      if (planillaId == null) throw Exception('No se pudo crear la planilla');

      final mimeType = _inferMimeType(_imageName!);

      List<CampoPreviewModel> campos;
      try {
        campos = await PlanillaService.proponerEstructura(
          planillaId: planillaId,
          fileBytes: _imageBytes!,
          filename: _imageName!,
          contentType: mimeType,
        );
      } catch (e) {
        // Eliminar la planilla creada si falla la propuesta de estructura
        try { await PlanillaService.eliminarPlanilla(planillaId); } catch (_) {}
        rethrow;
      }

      if (campos.isEmpty) {
        try { await PlanillaService.eliminarPlanilla(planillaId); } catch (_) {}
        throw Exception('No se detectaron campos en la planilla');
      }

      final rawFieldDefs = _buildFieldDefs(campos);
      final safeFieldDefs = sanitizeFieldDefs(rawFieldDefs);

      final estructuraJson = _buildEstructuraJson(campos, safeFieldDefs);

      Planilla planillaResp;
      try {
        planillaResp = await PlanillaService.digitalizarPlanilla(
          planillaId: planillaId,
          fileBytes: _imageBytes!,
          filename: _imageName!,
          estructuraJson: estructuraJson,
          contentType: mimeType,
        );
      } catch (e) {
        // Eliminar la planilla si falla la digitalización
        try { await PlanillaService.eliminarPlanilla(planillaId); } catch (_) {}
        rethrow;
      }

      final rawRecords = await _mapPlanillaToRecords(planillaResp, safeFieldDefs);
      final safeRecords = sanitizeRecords(rawRecords, safeFieldDefs);
      final uiImage = await _decodeUiImage(_imageBytes!);

      final planillaDigital = PlanillaDigital(
        eventId: widget.eventId,
        eventName: widget.eventName,
        date: DateTime.now(),
        referenceImage: uiImage,
        fieldDefs: safeFieldDefs,
        records: safeRecords,
      );

      ref.read(planillaProvider.notifier).setPlanilla(planillaDigital);

      if (mounted) {
        context.push('/planilla-digital/preview');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Digitalizar planilla'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.eventName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900)),
              const SizedBox(height: 12),
              Text(
                'Tomaremos una foto de la planilla fisica para digitalizarla.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              if (_imageBytes != null)
                Container(
                  height: 450,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.errorColor)),
              ],
              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator(color: AppTheme.primaryColor)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 20),
                      label: const Text('Tomar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _seleccionarArchivoExplorador,
                      icon: const Icon(Icons.folder_open_outlined, size: 20),
                      label: const Text('Seleccionar planilla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Formatos: JPG, PNG, PDF, ZIP',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
