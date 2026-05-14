import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
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
        // 'nombre' is required — backend getTipoCampoFromEstructura reads
        // enc.path("nombre") to resolve the tipo_campo for each column.
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
        // Find the CampoPreviewModel that matches this fieldDef
        final campo = campos.where(
          (c) => _normalize(c.nombreCampo) == _normalize(def.label),
        ).firstOrNull;
        if (campo == null) continue;

        // Find the dato for this campo in the current fila
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

  /// Sanitiza fieldDefs: fuerza signature_file si el nombre contiene "firma".
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

  /// Sanitiza records: limpia signatureBytes/source si hay campos de firma.
  List<StudentRecord> sanitizeRecords(
      List<StudentRecord> raw, List<PlanillaFieldDef> fieldDefs) {
    final hasSig = fieldDefs.any((f) => f.type == 'signature_file');
    if (!hasSig) return raw;
    return raw.map((r) => r.copyWith(signatureBytes: null, signatureSource: null)).toList();
  }

  /// Construye PlanillaFieldDef desde los campos detectados por OCR.
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

    try {
      final planilla = await PlanillaService.crearPlanilla({
        'eventoId': int.parse(widget.eventId),
        'origenId': 1,
      });
      final planillaId = planilla.id;
      if (planillaId == null) throw Exception('No se pudo crear la planilla');

      final mimeType = _inferMimeType(_imageName!);
      final campos = await PlanillaService.proponerEstructura(
        planillaId: planillaId,
        fileBytes: _imageBytes!,
        filename: _imageName!,
        contentType: mimeType,
      );
      if (campos.isEmpty) {
        throw Exception('No se detectaron campos en la planilla');
      }

      final rawFieldDefs = _buildFieldDefs(campos);
      final safeFieldDefs = sanitizeFieldDefs(rawFieldDefs);

      final estructuraJson = _buildEstructuraJson(campos, safeFieldDefs);
      final planillaResp = await PlanillaService.digitalizarPlanilla(
        planillaId: planillaId,
        fileBytes: _imageBytes!,
        filename: _imageName!,
        estructuraJson: estructuraJson,
        contentType: mimeType,
      );

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
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Tomar/Seleccionar imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
