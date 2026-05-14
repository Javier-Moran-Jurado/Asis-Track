import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/planilla.dart';
import '../../services/fila_service.dart';
import '../../services/planilla_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';

class DigitalizarPlanillaScreen extends StatefulWidget {
  const DigitalizarPlanillaScreen({super.key});

  @override
  State<DigitalizarPlanillaScreen> createState() =>
      _DigitalizarPlanillaScreenState();
}

class _DigitalizarPlanillaScreenState extends State<DigitalizarPlanillaScreen> {
  final ImagePicker _picker = ImagePicker();

  List<EventoPlanilla> _eventos = [];
  EventoPlanilla? _eventoSeleccionado;
  bool _cargandoEventos = true;

  List<CampoPreviewModel> _camposPlanilla = [];
  bool _cargandoCampos = false;

  XFile? _imagenFile;
  Uint8List? _imagenBytes;
  bool _procesandoImagen = false;

  bool _enviando = false;
  String? _error;

  Planilla? _planillaDigitalizada;

  List<CampoPreviewModel> get _camposPreview {
    if (_planillaDigitalizada?.campos != null &&
        _planillaDigitalizada!.campos!.isNotEmpty) {
      return _planillaDigitalizada!.campos!;
    }
    return _camposPlanilla;
  }

  List<FilaDigitalizada> get _filasPreview =>
      _planillaDigitalizada?.filas ?? const [];

  bool get _tieneFirma =>
      _camposPreview.any((c) => c.tipoCampo.tipo == 'signature_file');

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() {
      _cargandoEventos = true;
      _error = null;
    });
    try {
      final eventos = await PlanillaService.obtenerEventos();
      if (mounted) {
        setState(() {
          _eventos = eventos;
          _cargandoEventos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _cargandoEventos = false;
        });
      }
    }
  }

  Future<void> _seleccionarImagen({required bool desdeCamara}) async {
    setState(() => _procesandoImagen = true);
    final source = desdeCamara ? ImageSource.camera : ImageSource.gallery;
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img == null) {
      if (mounted) setState(() => _procesandoImagen = false);
      return;
    }

    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imagenFile = img;
      _imagenBytes = bytes;
      _procesandoImagen = false;
      _planillaDigitalizada = null;
    });
  }

  void _limpiar() {
    setState(() {
      _camposPlanilla = [];
      _imagenFile = null;
      _imagenBytes = null;
      _planillaDigitalizada = null;
      _error = null;
    });
  }

  String _buildEstructuraJsonFromCampos(List<CampoPreviewModel> campos) {
    final encabezados = campos
        .map((c) => {'nombre': c.nombreCampo, 'tipo_campo': c.tipoCampo.tipo})
        .toList();
    return jsonEncode({'encabezados': encabezados});
  }

  String _inferMimeType(String filename, String? provided) {
    if (provided != null && provided.isNotEmpty) return provided;
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'image/jpeg';
  }

  Future<void> _digitalizar() async {
    if (_eventoSeleccionado == null) {
      ErrorDialog.show(context, 'Selecciona un evento para continuar');
      return;
    }
    if (_imagenFile == null || _imagenBytes == null) {
      ErrorDialog.show(context, 'Selecciona una imagen antes de digitalizar');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
      _planillaDigitalizada = null;
    });

    try {
      final nuevaPlanilla = await PlanillaService.crearPlanilla({
        'eventoId': _eventoSeleccionado!.id,
        'origenId': 1,
      });
      final planillaId = nuevaPlanilla.id;
      if (planillaId == null) {
        throw Exception('No se pudo crear la planilla');
      }

      final mimeType = _inferMimeType(_imagenFile!.name, _imagenFile!.mimeType);
      setState(() {
        _cargandoCampos = true;
      });

      final campos = await PlanillaService.proponerEstructura(
        planillaId: planillaId,
        fileBytes: _imagenBytes!,
        filename: _imagenFile!.name,
        contentType: mimeType,
      );
      if (campos.isEmpty) {
        throw Exception('No se detectaron campos en la planilla');
      }

      final estructuraJson = _buildEstructuraJsonFromCampos(campos);
      final planilla = await PlanillaService.digitalizarPlanilla(
        planillaId: planillaId,
        fileBytes: _imagenBytes!,
        filename: _imagenFile!.name,
        estructuraJson: estructuraJson,
        contentType: mimeType,
      );

      if (mounted) {
        setState(() {
          _camposPlanilla = campos;
          _planillaDigitalizada = planilla;
          _cargandoCampos = false;
          _enviando = false;
        });
      }
      if (mounted && planilla.id != null) {
        context.push('/planillas/digitalizar/preview/${planilla.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _cargandoCampos = false;
          _enviando = false;
        });
        ErrorDialog.show(context, _error ?? 'Error al digitalizar');
      }
    }
  }

  Future<void> _refrescarPlanillaDigitalizada() async {
    final id = _planillaDigitalizada?.id;
    if (id == null) return;
    try {
      final planilla = await PlanillaService.obtenerPlanilla(id);
      if (mounted) {
        setState(() {
          _planillaDigitalizada = planilla;
        });
      }
    } catch (_) {}
  }

  Future<void> _abrirRecorteFirma(
      FilaDigitalizada fila, CampoPreviewModel campo) async {
    final filaId = fila.id;
    final campoId = campo.id;
    if (filaId == null || campoId == null) return;
    if (_imagenBytes == null) {
      ErrorDialog.show(context, 'No hay imagen de referencia para recortar');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SignatureCropDialog(
        imageBytes: _imagenBytes!,
        onConfirm: (croppedBytes) async {
          await FilaService.subirFirma(filaId, campoId, croppedBytes);
          await _refrescarPlanillaDigitalizada();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 16,
        title: const Text('Digitalizar planilla'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: AppBreakpoints.responsivePadding(context),
        child: _cargandoEventos
            ? _buildLoading()
            : isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('Cargando eventos...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildConfigSection(),
        const SizedBox(height: 24),
        _buildPreviewSection(isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildConfigSection()),
        const SizedBox(width: 24),
        Expanded(child: _buildPreviewSection(isMobile: false)),
      ],
    );
  }

  Widget _buildConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Configuracion',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900)),
        const SizedBox(height: 4),
        Text('Selecciona el evento y sube la imagen',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),

        _buildEventoSelector(),
        const SizedBox(height: 12),
        if (_cargandoCampos)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        if (_camposPlanilla.isNotEmpty) _buildCamposChips(),
        const SizedBox(height: 24),

        _buildImagenSection(),
        const SizedBox(height: 16),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_error!,
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center),
          ),

        CustomButton(
          text: 'Digitalizar y guardar',
          isPrimary: true,
          isLoading: _enviando,
          onPressed: _enviando ? null : _digitalizar,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Limpiar',
          isPrimary: false,
          isLoading: _enviando,
          onPressed: _enviando ? null : _limpiar,
        ),
      ],
    );
  }

  Widget _buildEventoSelector() {
    if (_eventos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('No hay eventos disponibles'),
      );
    }

    return DropdownButtonFormField<EventoPlanilla>(
      value: _eventoSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Evento',
        hintText: 'Selecciona un evento',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: _eventos
          .map((e) => DropdownMenuItem<EventoPlanilla>(
                value: e,
                child: Text(e.nombre),
              ))
          .toList(),
      onChanged: _enviando
          ? null
          : (e) {
              setState(() {
                _eventoSeleccionado = e;
                _camposPlanilla = [];
                _planillaDigitalizada = null;
                _error = null;
              });
            },
    );
  }

  Widget _buildCamposChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_camposPlanilla.length} campos detectados',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _camposPlanilla
              .map((c) => Chip(
                    label: Text(c.nombreCampo),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.08),
                    labelStyle: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildImagenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Captura de planilla',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900)),
        const SizedBox(height: 4),
        Text('Toma una foto o selecciona una imagen de la planilla fisica',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 12),

        if (_imagenBytes != null)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.memory(
                        _imagenBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppTheme.errorColor),
                      onPressed: _limpiar,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_imagenFile != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _imagenFile!.name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_imagenBytes == null)
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ImageActionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Tomar foto',
                      onTap: () => _seleccionarImagen(desdeCamara: true),
                    ),
                    const SizedBox(width: 24),
                    _ImageActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Seleccionar\nimagen',
                      onTap: () => _seleccionarImagen(desdeCamara: false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Formatos: JPG, PNG',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),

        if (_procesandoImagen)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Cargando imagen...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildPreviewSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vista previa',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900)),
        const SizedBox(height: 4),
        Text('Revisa los datos digitalizados antes de continuar',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),

        if (_planillaDigitalizada == null)
          Container(
            height: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_red_eye_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Aun no hay vista previa',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text('Digitaliza una planilla para ver los datos aqui',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),

        if (_planillaDigitalizada != null) ...[
          _buildPreviewHeader(),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _buildReferencePanel(height: 240),
            const SizedBox(height: 12),
            _buildDataPanel(height: 320),
          ] else
            SizedBox(
              height: 460,
              child: _BeforeAfterSlider(
                leftLabel: 'Referencia',
                rightLabel: 'Datos digitalizados',
                left: _buildReferencePanel(),
                right: _buildDataPanel(),
              ),
            ),
          const SizedBox(height: 12),
          if (_planillaDigitalizada?.id != null)
            CustomButton(
              text: 'Abrir planilla',
              isPrimary: false,
              onPressed: () => context.push('/planillas/llenar',
                  extra: _planillaDigitalizada!.id!),
            ),
        ],
      ],
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppTheme.secondaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _planillaDigitalizada?.nombreEvento ??
                      'Planilla #${_planillaDigitalizada?.id}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_camposPreview.length} campos  •  ${_filasPreview.length} registros',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (_tieneFirma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Firmas editables',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildReferencePanel({double? height}) {
    final imageWidget = _imagenBytes != null
        ? Image.memory(_imagenBytes!, fit: BoxFit.contain)
        : (_planillaDigitalizada?.urlReferencia != null
            ? Image.network(_planillaDigitalizada!.urlReferencia!,
                fit: BoxFit.contain)
            : const Icon(Icons.image_not_supported,
                size: 48, color: Colors.grey));

    final child = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InteractiveViewer(
          child: Center(child: imageWidget),
        ),
      ),
    );

    if (height == null) return child;
    return SizedBox(height: height, child: child);
  }

  Widget _buildDataPanel({double? height}) {
    final content = _filasPreview.isEmpty
        ? Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text('No se detectaron filas en la digitalizacion',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          )
        : _buildPreviewTable();

    final child = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: content,
    );

    if (height == null) return child;
    return SizedBox(height: height, child: child);
  }

  Widget _buildPreviewTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
            columns: [
              const DataColumn(
                  label: Text('#',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              ..._camposPreview.map((c) => DataColumn(
                    label: Text(c.nombreCampo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
            ],
            rows: _filasPreview.asMap().entries.map((entry) {
              final fila = entry.value;
              return DataRow(cells: [
                DataCell(Text('${fila.indice ?? entry.key + 1}')),
                ..._camposPreview.map((campo) {
                  final dato = fila.datos
                      .where((d) => d.campoId == campo.id)
                      .firstOrNull;
                  final valor = dato?.informacion?.toString() ?? '';

                  Widget cellContent;
                  if (valor.isEmpty && campo.tipoCampo.tipo != 'signature_file') {
                    cellContent = const Text('—');
                  } else if (campo.tipoCampo.tipo == 'signature_file') {
                    cellContent = _buildSignatureCell(fila, campo, valor);
                  } else {
                    cellContent = Text(valor, overflow: TextOverflow.ellipsis);
                  }

                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: cellContent,
                    ),
                  );
                }),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureCell(
      FilaDigitalizada fila, CampoPreviewModel campo, String valor) {
    final canEdit = _imagenBytes != null && fila.id != null && campo.id != null;
    return InkWell(
      onTap: canEdit ? () => _abrirRecorteFirma(fila, campo) : null,
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(
            height: 44,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: valor.isEmpty
                ? const Center(child: Text('Sin firma'))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      valor,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              size: 20, color: Colors.grey),
                    ),
                  ),
          ),
          if (canEdit)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.crop, size: 14, color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

class DigitalizarPreviewScreen extends StatefulWidget {
  final int planillaId;

  const DigitalizarPreviewScreen({super.key, required this.planillaId});

  @override
  State<DigitalizarPreviewScreen> createState() =>
      _DigitalizarPreviewScreenState();
}

class _DigitalizarPreviewScreenState extends State<DigitalizarPreviewScreen> {
  Planilla? _planilla;
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;

  List<CampoPreviewModel> get _camposPreview => _planilla?.campos ?? const [];
  List<FilaDigitalizada> get _filasPreview => _planilla?.filas ?? const [];

  bool get _tieneFirma =>
      _camposPreview.any((c) => c.tipoCampo.tipo == 'signature_file');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final planilla = await PlanillaService.obtenerPlanilla(widget.planillaId);
      Uint8List? bytes;
      final url = planilla.urlReferencia;
      if (url != null && url.isNotEmpty) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        }
      }
      if (mounted) {
        setState(() {
          _planilla = planilla;
          _imageBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _refrescarPlanilla() async {
    try {
      final planilla = await PlanillaService.obtenerPlanilla(widget.planillaId);
      if (mounted) {
        setState(() {
          _planilla = planilla;
        });
      }
    } catch (_) {}
  }

  Future<void> _abrirRecorteFirma(
      FilaDigitalizada fila, CampoPreviewModel campo) async {
    final filaId = fila.id;
    final campoId = campo.id;
    if (filaId == null || campoId == null) return;
    if (_imageBytes == null) {
      ErrorDialog.show(context, 'No hay imagen de referencia para recortar');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SignatureCropDialog(
        imageBytes: _imageBytes!,
        onConfirm: (croppedBytes) async {
          await FilaService.subirFirma(filaId, campoId, croppedBytes);
          await _refrescarPlanilla();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 16,
        title: const Text('Vista previa digitalizacion'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _cargar,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: AppBreakpoints.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPreviewHeader(),
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        SizedBox(height: 260, child: _buildReferencePanel()),
                        const SizedBox(height: 12),
                        SizedBox(height: 360, child: _buildDataPanel()),
                      ] else
                        SizedBox(
                          height: 520,
                          child: _BeforeAfterSlider(
                            leftLabel: 'Referencia',
                            rightLabel: 'Datos digitalizados',
                            left: _buildReferencePanel(),
                            right: _buildDataPanel(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Abrir planilla',
                        isPrimary: false,
                        onPressed: _planilla?.id == null
                            ? null
                            : () => context.push('/planillas/llenar',
                                extra: _planilla!.id!),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(_error ?? 'Error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppTheme.secondaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _planilla?.nombreEvento ?? 'Planilla #${_planilla?.id}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_camposPreview.length} campos  •  ${_filasPreview.length} registros',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (_tieneFirma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Firmas editables',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildReferencePanel() {
    final imageWidget = _imageBytes != null
        ? Image.memory(_imageBytes!, fit: BoxFit.contain)
        : (_planilla?.urlReferencia != null
            ? Image.network(_planilla!.urlReferencia!, fit: BoxFit.contain)
            : const Icon(Icons.image_not_supported,
                size: 48, color: Colors.grey));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InteractiveViewer(
          child: Center(child: imageWidget),
        ),
      ),
    );
  }

  Widget _buildDataPanel() {
    final content = _filasPreview.isEmpty
        ? Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text('No se detectaron filas en la digitalizacion',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          )
        : _buildPreviewTable();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: content,
    );
  }

  Widget _buildPreviewTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
            columns: [
              const DataColumn(
                  label: Text('#',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              ..._camposPreview.map((c) => DataColumn(
                    label: Text(c.nombreCampo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
            ],
            rows: _filasPreview.asMap().entries.map((entry) {
              final fila = entry.value;
              return DataRow(cells: [
                DataCell(Text('${fila.indice ?? entry.key + 1}')),
                ..._camposPreview.map((campo) {
                  final dato = fila.datos
                      .where((d) => d.campoId == campo.id)
                      .firstOrNull;
                  final valor = dato?.informacion?.toString() ?? '';

                  Widget cellContent;
                  if (valor.isEmpty && campo.tipoCampo.tipo != 'signature_file') {
                    cellContent = const Text('—');
                  } else if (campo.tipoCampo.tipo == 'signature_file') {
                    cellContent = _buildSignatureCell(fila, campo, valor);
                  } else {
                    cellContent = Text(valor, overflow: TextOverflow.ellipsis);
                  }

                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: cellContent,
                    ),
                  );
                }),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureCell(
      FilaDigitalizada fila, CampoPreviewModel campo, String valor) {
    final canEdit = _imageBytes != null && fila.id != null && campo.id != null;
    return InkWell(
      onTap: canEdit ? () => _abrirRecorteFirma(fila, campo) : null,
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(
            height: 44,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: valor.isEmpty
                ? const Center(child: Text('Sin firma'))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      valor,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              size: 20, color: Colors.grey),
                    ),
                  ),
          ),
          if (canEdit)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.crop, size: 14, color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 36),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterSlider extends StatefulWidget {
  final Widget left;
  final Widget right;
  final String leftLabel;
  final String rightLabel;
  final double initialRatio;

  const _BeforeAfterSlider({
    required this.left,
    required this.right,
    required this.leftLabel,
    required this.rightLabel,
    this.initialRatio = 0.5,
  });

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  late double _ratio;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(0.15, 0.85);
  }

  void _updateRatio(double width, double dx) {
    final next = (dx / width).clamp(0.15, 0.85);
    setState(() => _ratio = next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final handleLeft = width * _ratio;
        const handleWidth = 44.0;
        final handleOffset = handleLeft - handleWidth / 2;

        return Stack(
          children: [
            Positioned.fill(child: widget.right),
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _ratio,
                  child: widget.left,
                ),
              ),
            ),
            Positioned(
              left: handleOffset,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) =>
                    _updateRatio(width, handleOffset + details.localPosition.dx),
                onTapDown: (details) =>
                    _updateRatio(width, handleOffset + details.localPosition.dx),
                child: Container(
                  width: handleWidth,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _SliderLabel(text: widget.leftLabel),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _SliderLabel(text: widget.rightLabel),
            ),
          ],
        );
      },
    );
  }
}

class _SliderLabel extends StatelessWidget {
  final String text;

  const _SliderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray900,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SignatureCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<void> Function(Uint8List croppedBytes) onConfirm;

  const _SignatureCropDialog({
    required this.imageBytes,
    required this.onConfirm,
  });

  @override
  State<_SignatureCropDialog> createState() => _SignatureCropDialogState();
}

class _SignatureCropDialogState extends State<_SignatureCropDialog> {
  ui.Image? _image;
  Rect? _cropRect;
  Rect _imageRect = Rect.zero;
  Offset? _dragStart;
  bool _loadingImage = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = frame.image;
        _loadingImage = false;
      });
    }
  }

  void _startSelection(Offset localPosition) {
    if (!_imageRect.contains(localPosition)) return;
    setState(() {
      _dragStart = localPosition;
      _cropRect = Rect.fromPoints(localPosition, localPosition);
    });
  }

  void _updateSelection(Offset localPosition) {
    if (_dragStart == null) return;
    final rect = Rect.fromPoints(_dragStart!, localPosition);
    setState(() {
      _cropRect = _clampRect(rect);
    });
  }

  Rect _clampRect(Rect rect) {
    final left = math.min(rect.left, rect.right);
    final right = math.max(rect.left, rect.right);
    final top = math.min(rect.top, rect.bottom);
    final bottom = math.max(rect.top, rect.bottom);

    final clampedLeft = left.clamp(_imageRect.left, _imageRect.right);
    final clampedRight = right.clamp(_imageRect.left, _imageRect.right);
    final clampedTop = top.clamp(_imageRect.top, _imageRect.bottom);
    final clampedBottom = bottom.clamp(_imageRect.top, _imageRect.bottom);

    return Rect.fromLTRB(
      clampedLeft.toDouble(),
      clampedTop.toDouble(),
      clampedRight.toDouble(),
      clampedBottom.toDouble(),
    );
  }

  Future<Uint8List?> _cropImage() async {
    if (_image == null || _cropRect == null) return null;
    if (_cropRect!.width < 10 || _cropRect!.height < 10) return null;
    if (_imageRect.width <= 0 || _imageRect.height <= 0) return null;

    final scaleX = _image!.width / _imageRect.width;
    final scaleY = _image!.height / _imageRect.height;
    final srcRect = Rect.fromLTWH(
      (_cropRect!.left - _imageRect.left) * scaleX,
      (_cropRect!.top - _imageRect.top) * scaleY,
      _cropRect!.width * scaleX,
      _cropRect!.height * scaleY,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
    canvas.drawImageRect(_image!, srcRect, dstRect, Paint());
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(
      math.max(1, srcRect.width.round()),
      math.max(1, srcRect.height.round()),
    );
    final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _confirmCrop() async {
    if (_processing) return;
    setState(() => _processing = true);
    final bytes = await _cropImage();
    if (bytes == null) {
      if (mounted) {
        setState(() => _processing = false);
        ErrorDialog.show(context, 'Selecciona un area valida');
      }
      return;
    }
    await widget.onConfirm(bytes);
    if (mounted) {
      setState(() => _processing = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Recortar firma',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _processing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loadingImage
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final imgSize = Size(
                          _image!.width.toDouble(),
                          _image!.height.toDouble(),
                        );
                        final scale = math.min(
                          size.width / imgSize.width,
                          size.height / imgSize.height,
                        );
                        final displaySize =
                            Size(imgSize.width * scale, imgSize.height * scale);
                        final offset = Offset(
                          (size.width - displaySize.width) / 2,
                          (size.height - displaySize.height) / 2,
                        );
                        _imageRect = offset & displaySize;

                        final cropRect = _cropRect;
                        final buttonLeft = cropRect == null
                            ? 0.0
                            : (cropRect.right - 110)
                                .clamp(8.0, size.width - 120);
                        final buttonTop = cropRect == null
                            ? 0.0
                            : (cropRect.bottom + 8)
                                .clamp(8.0, size.height - 44);

                        return GestureDetector(
                          onPanStart: (d) => _startSelection(d.localPosition),
                          onPanUpdate: (d) => _updateSelection(d.localPosition),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  child: Center(
                                    child: SizedBox(
                                      width: displaySize.width,
                                      height: displaySize.height,
                                      child: Image.memory(
                                        widget.imageBytes,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (cropRect != null)
                                Positioned(
                                  left: cropRect.left,
                                  top: cropRect.top,
                                  width: cropRect.width,
                                  height: cropRect.height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 2),
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.05),
                                    ),
                                  ),
                                ),
                              if (cropRect != null)
                                Positioned(
                                  left: buttonLeft,
                                  top: buttonTop,
                                  child: ElevatedButton(
                                    onPressed: _processing ? null : _confirmCrop,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: _processing
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text('Confirmar'),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Arrastra para seleccionar el recorte',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                  TextButton(
                    onPressed: _processing
                        ? null
                        : () => setState(() => _cropRect = null),
                    child: const Text('Reiniciar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}