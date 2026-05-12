import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DigitalizarPlanillaScreen extends StatefulWidget {
  const DigitalizarPlanillaScreen({super.key});

  @override
  State<DigitalizarPlanillaScreen> createState() =>
      _DigitalizarPlanillaScreenState();
}

class _DigitalizarPlanillaScreenState extends State<DigitalizarPlanillaScreen> {
  // Imagen
  String? _imagenPath;
  bool _procesandoImagen = false;

  // Datos digitalizados
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();

  bool _enviando = false;
  bool _exito = false;
  String? _error;

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOCK: Simula el reconocimiento OCR de una imagen
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, String> _digitalizarMock() {
    return {
      'cedula': '1234567890',
      'nombres': 'Juan Pedro',
      'apellidos': 'García López',
    };
  }

  void _seleccionarImagen({bool desdeCamara = false}) async {
    // TODO: Conectar con image_picker cuando esté listo
    // final picker = ImagePicker();
    // final XFile? img = desdeCamara
    //     ? await picker.pickImage(source: ImageSource.camera)
    //     : await picker.pickImage(source: ImageSource.gallery);

    setState(() => _procesandoImagen = true);

    // Simula captura de imagen
    await Future.delayed(const Duration(seconds: 1));
    final path = desdeCamara ? 'foto_camara.jpg' : 'imagen_galeria.jpg';

    if (!mounted) return;
    setState(() {
      _imagenPath = path;
      _procesandoImagen = false;
    });

    // Simula OCR después de obtener imagen
    _ejecutarOcr();
  }

  void _ejecutarOcr() async {
    setState(() => _procesandoImagen = true);

    // Simula tiempo de procesamiento OCR
    await Future.delayed(const Duration(milliseconds: 1500));

    final datos = _digitalizarMock();

    if (!mounted) return;
    setState(() {
      _cedulaCtrl.text = datos['cedula'] ?? '';
      _nombresCtrl.text = datos['nombres'] ?? '';
      _apellidosCtrl.text = datos['apellidos'] ?? '';
      _procesandoImagen = false;
    });
  }

  void _limpiar() {
    setState(() {
      _imagenPath = null;
      _cedulaCtrl.clear();
      _nombresCtrl.clear();
      _apellidosCtrl.clear();
      _error = null;
    });
  }

  Future<void> _confirmar() async {
    setState(() { _enviando = true; _error = null; });

    // TODO: Conectar con endpoint real del backend
    // POST /api/v1/planilla-service/planillas/digitalizar
    // Body: multipart con imagen + datos reconocidos
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _enviando = false;
      _exito = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_exito) return _buildExito();

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
        child: _procesandoImagen && _imagenPath == null
            ? _buildLoading()
            : isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOADING
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoading() {
    return const SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('Procesando imagen...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT (stacked)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImagenSection(),
        const SizedBox(height: 24),
        _buildDatosSection(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP LAYOUT (side by side)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildImagenSection()),
        const SizedBox(width: 24),
        Expanded(child: _buildDatosSection()),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLUMNA IZQUIERDA: Imagen
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildImagenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Captura de planilla',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        const SizedBox(height: 4),
        Text('Toma una foto o selecciona una imagen de la planilla física',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 12),

        if (_imagenPath != null)
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image, size: 64, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(_imagenPath!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray900)),
                          const SizedBox(height: 4),
                          Text('Imagen capturada — acerca/aleja con gestos',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
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
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                      onPressed: _limpiar,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_imagenPath == null)
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

        if (_procesandoImagen && _imagenPath != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Reconociendo datos...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLUMNA DERECHA: Datos digitalizados
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDatosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Datos reconocidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        const SizedBox(height: 4),
        Text('Verifica y corrige los datos si es necesario',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Cédula',
          hintText: 'Número de documento',
          controller: _cedulaCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Nombres',
          hintText: 'Nombres del estudiante',
          controller: _nombresCtrl,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Apellidos',
          hintText: 'Apellidos del estudiante',
          controller: _apellidosCtrl,
        ),
        const SizedBox(height: 24),

        // ── Error ──
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_error!,
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center),
          ),

        // ── Botones ──
        CustomButton(
          text: 'Confirmar ajustes',
          isPrimary: true,
          isLoading: _enviando,
          onPressed:
              (_enviando || _imagenPath == null) ? null : _confirmar,
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

  // ══════════════════════════════════════════════════════════════════════════
  // VISTA DE ÉXITO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildExito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 32),
            const Text('Planilla digitalizada',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
            const SizedBox(height: 12),
            const Text('Los datos han sido procesados y guardados correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Volver a planillas',
              isPrimary: true,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOTÓN DE ACCIÓN DE IMAGEN
// ════════════════════════════════════════════════════════════════════════════
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
