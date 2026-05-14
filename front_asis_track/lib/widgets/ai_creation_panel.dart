import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/planilla.dart';
import '../services/planilla_service.dart';
import '../themes/app_theme.dart';
import 'error_dialog.dart';

enum AiCreationMode { imagen, descripcion }

/// Panel que permite crear una planilla completa usando IA:
/// - [imagen]: sube una foto de planilla física → el backend propone los campos
/// - [descripcion]: describe el evento → el backend genera la planilla completa
class AiCreationPanel extends StatefulWidget {
  /// Planilla base ya creada (debe existir antes de llamar proponer-estructura).
  final int planillaId;
  final EventoPlanilla? eventoSeleccionado;
  final AiCreationMode initialMode;

  /// Devuelve los campos generados al padre cuando se completa el flujo de imagen.
  final void Function(List<CampoPreviewModel> campos)? onCamposGenerados;

  /// Devuelve la planilla completa al padre cuando se usa el modo descripción.
  final void Function(Planilla planilla)? onPlanillaGenerada;

  const AiCreationPanel({
    super.key,
    required this.planillaId,
    this.eventoSeleccionado,
    this.initialMode = AiCreationMode.imagen,
    this.onCamposGenerados,
    this.onPlanillaGenerada,
  });

  @override
  State<AiCreationPanel> createState() => _AiCreationPanelState();
}

class _AiCreationPanelState extends State<AiCreationPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Modo imagen ──
  Uint8List? _imageBytes;
  String _imageFilename = '';
  String _imageContentType = 'image/jpeg';
  bool _procesandoImagen = false;

  // ── Modo descripción ──
  final _descController = TextEditingController();
  bool _procesandoDesc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialMode == AiCreationMode.imagen ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGEN
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _imageFilename = picked.name;
        _imageContentType = _mimeFromExt(picked.name.split('.').last);
      });
    }
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _analizarImagen() async {
    if (_imageBytes == null) {
      ErrorDialog.show(context, 'Selecciona una imagen primero');
      return;
    }
    setState(() => _procesandoImagen = true);
    try {
      final campos = await PlanillaService.proponerEstructura(
        planillaId: widget.planillaId,
        fileBytes: _imageBytes!.toList(),
        filename: _imageFilename,
        contentType: _imageContentType,
      );
      if (mounted) {
        widget.onCamposGenerados?.call(campos);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context,
            'Error analizando imagen: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _procesandoImagen = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESCRIPCIÓN
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _generarDesdeDescripcion() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ErrorDialog.show(context, 'Escribe una descripción del evento o planilla');
      return;
    }
    setState(() => _procesandoDesc = true);
    try {
      final planilla = await PlanillaService.generarPropuestaIA(
        descripcion: desc,
        eventoId: widget.eventoSeleccionado?.id,
      );
      if (mounted) {
        widget.onPlanillaGenerada?.call(planilla);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context,
            'Error generando planilla: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _procesandoDesc = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D5BF0).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D5BF0).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header degradado ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1D5BF0).withValues(alpha: 0.08),
                  const Color(0xFF7C3AED).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D5BF0), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear con Inteligencia Artificial',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'El sistema analiza y genera los campos automáticamente',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.image_outlined, size: 18),
                  text: 'Desde imagen',
                ),
                Tab(
                  icon: Icon(Icons.text_fields_outlined, size: 18),
                  text: 'Desde descripción',
                ),
              ],
            ),
          ),

          // ── Tab content ──
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImagenTab(),
                _buildDescripcionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: imagen ───────────────────────────────────────────────────────────
  Widget _buildImagenTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sube una foto de una planilla física. La IA detectará los campos automáticamente.',
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Drop zone / preview
          Expanded(
            child: GestureDetector(
              onTap: _procesandoImagen ? null : _seleccionarImagen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _imageBytes != null
                      ? Colors.transparent
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imageBytes != null
                        ? AppTheme.primaryColor.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: _imageBytes != null ? 2 : 1,
                  ),
                ),
                child: _imageBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _seleccionarImagen,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Toca para seleccionar imagen',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG, WEBP',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: (_procesandoImagen || _imageBytes == null)
                  ? null
                  : _analizarImagen,
              icon: _procesandoImagen
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _procesandoImagen ? 'Analizando imagen…' : 'Analizar con IA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: descripción ──────────────────────────────────────────────────────
  Widget _buildDescripcionTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16,
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Describe el evento o el tipo de planilla y la IA la generará completa con sus campos.',
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Textarea
          Expanded(
            child: TextField(
              controller: _descController,
              enabled: !_procesandoDesc,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText:
                    'Ejemplo: "Planilla de asistencia para taller de programación con campos de nombre, código estudiantil, programa académico y firma"',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _procesandoDesc ? null : _generarDesdeDescripcion,
              icon: _procesandoDesc
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _procesandoDesc ? 'Generando planilla…' : 'Generar planilla con IA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
