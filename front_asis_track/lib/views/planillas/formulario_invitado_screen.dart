import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/planilla.dart';
import '../../services/planilla_service.dart';
import '../../services/campo_service.dart';
import '../../services/fila_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/error_dialog.dart';

class FormularioInvitadoScreen extends StatefulWidget {
  final int planillaId;

  const FormularioInvitadoScreen({super.key, required this.planillaId});

  @override
  State<FormularioInvitadoScreen> createState() => _FormularioInvitadoScreenState();
}

class _FormularioInvitadoScreenState extends State<FormularioInvitadoScreen> {
  Planilla? _planilla;
  List<CampoPreviewModel> _campos = [];
  bool _isLoading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  late final Map<int, TextEditingController> _controllers = {};
  late final Map<int, String?> _selectedValues = {};
  late final Map<int, Set<String>> _checkedValues = {};
  late final Map<int, bool> _checkboxValues = {};
  late final Map<int, Uint8List?> _signatureBytes = {};
  bool _guardando = false;
  bool _enviado = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final p = await PlanillaService.obtenerPlanilla(widget.planillaId);
      final camposList = await CampoService.obtenerCampos(widget.planillaId);

      for (final c in camposList) {
        _controllers[c.id!] = TextEditingController();
        _checkboxValues[c.id!] = false;
        _checkedValues[c.id!] = {};
        _selectedValues[c.id!] = null;
        if (c.tipoCampo.tipo == 'signature_file') {
          _signatureBytes[c.id!] = null;
        }
      }

      setState(() {
        _planilla = p;
        _campos = camposList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar GPS si el evento tiene coordenadas configuradas
    if (_planilla?.eventoCoordenadas != null && _planilla!.eventoCoordenadas!.isNotEmpty) {
      final coords = _planilla!.eventoCoordenadas!.split(',');
      if (coords.length >= 2) {
        final latEvento = double.tryParse(coords[0].trim());
        final lngEvento = double.tryParse(coords[1].trim());

        if (latEvento != null && lngEvento != null) {
          setState(() => _guardando = true);
          try {
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) throw Exception('Los servicios de ubicación están desactivados.');

            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) throw Exception('Permisos de ubicación denegados.');
            }
            if (permission == LocationPermission.deniedForever) {
              throw Exception('Permisos de ubicación denegados permanentemente.');
            }

            Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
            double distanceInMeters = Geolocator.distanceBetween(position.latitude, position.longitude, latEvento, lngEvento);

            if (distanceInMeters > 50.0) {
              if (mounted) ErrorDialog.show(context, 'No puedes registrarte. Estás a \${distanceInMeters.toStringAsFixed(1)} metros del evento (límite 50m).');
              setState(() => _guardando = false);
              return;
            }
          } catch (e) {
            if (mounted) ErrorDialog.show(context, "Error verificando ubicación: \${e.toString().replaceFirst('Exception: ', '')}");
            setState(() => _guardando = false);
            return;
          }
        }
      }
    }
    
    // Check required signatures
    for (final c in _campos) {
      if (c.tipoCampo.tipo == 'signature_file' && c.obligatorio && _signatureBytes[c.id!] == null) {
        ErrorDialog.show(context, 'Falta la firma en el campo "\${c.nombreCampo}".');
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final datos = <Map<String, dynamic>>[];
      for (final c in _campos) {
        String info = '';
        switch (c.tipoCampo.tipo) {
          case 'checkbox':
            info = _checkboxValues[c.id!].toString();
            break;
          case 'combo':
          case 'radio':
            info = _selectedValues[c.id!] ?? '';
            break;
          case 'multivaluecheckbox':
            info = _checkedValues[c.id!]!.join(', ');
            break;
          case 'signature_file':
            info = 'Pendiente'; // Will be updated via S3
            break;
          default:
            info = _controllers[c.id!]?.text.trim() ?? '';
        }
        datos.add({'campoId': c.id, 'posicion': 0, 'informacion': info});
      }

      final res = await FilaService.crearFila({
        'planillaId': widget.planillaId,
        'datos': datos,
      });
      final filaId = res['id'] as int;

      for (final c in _campos) {
        if (c.tipoCampo.tipo == 'signature_file' && _signatureBytes[c.id!] != null) {
          await FilaService.subirFirma(filaId, c.id!, _signatureBytes[c.id!]!);
        }
      }

      setState(() => _enviado = true);
    } catch (e) {
      if (mounted) ErrorDialog.show(context, "Error al enviar: ${e.toString().replaceFirst('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildFieldCard(CampoPreviewModel campo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(campo.nombreCampo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                if (campo.obligatorio) const Text('*', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputForField(campo),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForField(CampoPreviewModel campo) {
    String tipoEfectivo = campo.tipoCampo.tipo;
    final nombreLower = campo.nombreCampo.toLowerCase();
    
    if (tipoEfectivo == 'text') {
      if (nombreLower.contains('cedul') || nombreLower.contains('cédul') || nombreLower.contains('telefon') || nombreLower.contains('teléfon') || nombreLower.contains('edad')) {
        tipoEfectivo = 'numeric';
      } else if (nombreLower.contains('correo') || nombreLower.contains('email')) {
        tipoEfectivo = 'email';
      } else if (nombreLower.contains('contraseña') || nombreLower.contains('password')) {
        tipoEfectivo = 'secret';
      }
    }

    switch (tipoEfectivo) {
      case 'text':
      case 'email':
      case 'secret':
        return TextFormField(
          controller: _controllers[campo.id!],
          obscureText: tipoEfectivo == 'secret',
          keyboardType: tipoEfectivo == 'email' ? TextInputType.emailAddress : TextInputType.text,
          decoration: const InputDecoration(hintText: 'Tu respuesta', border: UnderlineInputBorder()),
          validator: (v) {
            if (campo.obligatorio && (v == null || v.trim().isEmpty)) return 'Esta pregunta es obligatoria';
            if (tipoEfectivo == 'email' && v != null && v.trim().isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(v.trim())) return 'Correo inválido';
            }
            return null;
          },
        );

      case 'numeric':
        return TextFormField(
          controller: _controllers[campo.id!],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'Tu respuesta (solo números)', border: UnderlineInputBorder()),
          validator: (v) {
            if (campo.obligatorio && (v == null || v.trim().isEmpty)) return 'Esta pregunta es obligatoria';
            return null;
          },
        );

      case 'date':
        return TextFormField(
          controller: _controllers[campo.id!],
          readOnly: true,
          decoration: const InputDecoration(hintText: 'dd/mm/aaaa', border: UnderlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
            if (date != null) {
              _controllers[campo.id!]!.text = "\${date.day.toString().padLeft(2, '0')}/\${date.month.toString().padLeft(2, '0')}/\${date.year}";
            }
          },
          validator: (v) => campo.obligatorio && (v == null || v.isEmpty) ? 'Esta pregunta es obligatoria' : null,
        );

      case 'checkbox':
        return CheckboxListTile(
          title: const Text('Sí'),
          value: _checkboxValues[campo.id!],
          onChanged: (v) => setState(() => _checkboxValues[campo.id!] = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case 'combo':
      case 'radio':
        return DropdownButtonFormField<String>(
          value: _selectedValues[campo.id!],
          items: campo.opciones.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (v) => setState(() => _selectedValues[campo.id!] = v),
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          validator: (v) => campo.obligatorio && v == null ? 'Esta pregunta es obligatoria' : null,
          hint: const Text('Seleccionar'),
        );

      case 'multivaluecheckbox':
        return Column(
          children: campo.opciones.map((opt) {
            final isChecked = _checkedValues[campo.id!]!.contains(opt);
            return CheckboxListTile(
              title: Text(opt),
              value: isChecked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _checkedValues[campo.id!]!.add(opt);
                  } else {
                    _checkedValues[campo.id!]!.remove(opt);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );

      case 'signature_file':
        final bytes = _signatureBytes[campo.id!];
        final hasBytes = bytes != null;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasBytes) ...[
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(bytes, height: 100, fit: BoxFit.contain)),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  final newBytes = await showDialog<Uint8List?>(context: context, builder: (_) => const _GuestSignatureDialog());
                  if (newBytes != null) setState(() => _signatureBytes[campo.id!] = newBytes);
                },
                icon: const Icon(Icons.draw),
                label: Text(hasBytes ? 'Cambiar Firma' : 'Dibujar o Subir Firma'),
              ),
            ],
          ),
        );

      default:
        return TextFormField(controller: _controllers[campo.id!], decoration: const InputDecoration(hintText: 'Tu respuesta', border: UnderlineInputBorder()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));

    if (_enviado) {
      return Scaffold(
        backgroundColor: AppTheme.gray50,
        body: Center(
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  const Text('Se ha registrado tu respuesta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Tus datos han sido enviados correctamente a la planilla "\${_planilla!.nombreEvento}".', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Volver al inicio'),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF8), // Google Forms purpleish background
      appBar: AppBar(
        title: const Text('Formulario'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(height: 10, decoration: const BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.vertical(top: Radius.circular(12)))),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_planilla!.nombreEvento ?? 'Planilla \${_planilla!.id}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('* Obligatorio', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form fields
              Form(
                key: _formKey,
                child: Column(
                  children: _campos.map((c) => _buildFieldCard(c)).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _guardando ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _guardando 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enviar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _formKey.currentState?.reset(),
                    child: const Text('Borrar formulario', style: TextStyle(color: AppTheme.primaryColor)),
                  )
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODAL DE FIRMA
// ═══════════════════════════════════════════════════════════════════════════════

class _GuestSignatureDialog extends StatefulWidget {
  const _GuestSignatureDialog();

  @override
  State<_GuestSignatureDialog> createState() => _GuestSignatureDialogState();
}

class _GuestSignatureDialogState extends State<_GuestSignatureDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SignatureController _signatureController = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  Uint8List? _uploadedImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _uploadedImage = bytes);
    }
  }

  Future<void> _guardar() async {
    Uint8List? bytes;
    if (_tabController.index == 0) {
      if (_signatureController.isNotEmpty) bytes = await _signatureController.toPngBytes();
    } else {
      bytes = _uploadedImage;
    }
    if (mounted) Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Firma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [Tab(icon: Icon(Icons.draw), text: 'Dibujar'), Tab(icon: Icon(Icons.image), text: 'Subir Imagen')],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: Signature(controller: _signatureController, backgroundColor: Colors.white))),
                      TextButton.icon(onPressed: () => _signatureController.clear(), icon: const Icon(Icons.clear, size: 16), label: const Text('Limpiar')),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadedImage != null) Expanded(child: Image.memory(_uploadedImage!, fit: BoxFit.contain))
                      else const Expanded(child: Center(child: Text('Ninguna imagen seleccionada'))),
                      ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.upload_file), label: const Text('Seleccionar Imagen')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
