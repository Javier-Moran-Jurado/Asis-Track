import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firma_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/firma_canvas_widget.dart';

class FirmaScreen extends StatefulWidget {
  const FirmaScreen({super.key});

  @override
  State<FirmaScreen> createState() => _FirmaScreenState();
}

class _FirmaScreenState extends State<FirmaScreen> {
  // Estados del flujo
  bool _seleccionando = true;
  String? _imagenSeleccionada;
  String? _modo; // 'imagen' o 'dibujo'
  bool _tieneFirma = false;

  bool _enviando = false;
  bool _exito = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Firma digital'),
        centerTitle: false,
      ),
      body: _exito
          ? _buildExitoView()
          : _seleccionando
              ? _buildSeleccion()
              : _construirFlujo(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PANTALLA DE SELECCIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSeleccion() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
        child: SingleChildScrollView(
          padding: AppBreakpoints.responsivePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.draw_outlined,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Firma digital',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona cómo quieres crear tu firma digital',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _OpcionCard(
                      icon: Icons.image_outlined,
                      title: 'Subir imagen',
                      subtitle: 'Selecciona una imagen\nde tu galería o cámara',
                      color: AppTheme.secondaryColor,
                      onTap: () async {
                        final img = await FirmaService.seleccionarImagen();
                        if (img != null && mounted) {
                          setState(() {
                            _modo = 'imagen';
                            _imagenSeleccionada = img;
                            _seleccionando = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OpcionCard(
                      icon: Icons.draw_outlined,
                      title: 'Dibujar firma',
                      subtitle: 'Dibuja tu firma\ncon el dedo',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        setState(() {
                          _modo = 'dibujo';
                          _seleccionando = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FLUJO ACTIVO (imagen o dibujo)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _construirFlujo() {
    if (_modo == 'imagen') return _buildFlujoImagen();
    return _buildFlujoDibujo();
  }

  // ── Flujo: Subir imagen ──────────────────────────────────────────────────
  Widget _buildFlujoImagen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
        child: SingleChildScrollView(
          padding: AppBreakpoints.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Vista previa de la firma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _imagenSeleccionada ?? 'firma.jpg',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Imagen seleccionada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: AppTheme.errorColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_enviando) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                ),
              ],
              CustomButton(
                text: 'Confirmar firma',
                isPrimary: true,
                isLoading: _enviando,
                onPressed: _enviando ? null : () => _enviarFirma(),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Cancelar',
                isPrimary: false,
                isLoading: _enviando,
                onPressed: _enviando
                    ? null
                    : () => setState(() {
                          _seleccionando = true;
                          _imagenSeleccionada = null;
                          _error = null;
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Flujo: Dibujar ───────────────────────────────────────────────────────
  Widget _buildFlujoDibujo() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
        child: SingleChildScrollView(
          padding: AppBreakpoints.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Dibuja tu firma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Usa tu dedo para dibujar en el área de abajo',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: FirmaCanvasWidget(
                  onFirmaChanged: (tiene) => setState(() => _tieneFirma = tiene),
                  onClear: () => setState(() => _tieneFirma = false),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _tieneFirma = false);
                },
                icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: AppTheme.errorColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_enviando) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                ),
              ],
              CustomButton(
                text: 'Guardar y confirmar',
                isPrimary: true,
                isLoading: _enviando,
                onPressed:
                    (_enviando || !_tieneFirma) ? null : () => _enviarFirma(),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Cancelar',
                isPrimary: false,
                isLoading: _enviando,
                onPressed: _enviando
                    ? null
                    : () => setState(() {
                          _seleccionando = true;
                          _error = null;
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENVÍO
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _enviarFirma() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    final archivo = _modo == 'imagen'
        ? (_imagenSeleccionada ?? 'firma.jpg')
        : 'firma_dibujo.png';

    try {
      final success = await FirmaService.enviarFirma(
        archivo: archivo,
        tipo: _modo,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _enviando = false;
          _exito = true;
        });
      } else {
        setState(() {
          _enviando = false;
          _error = 'No se pudo enviar la firma. Intenta de nuevo.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'Error: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VISTA DE ÉXITO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildExitoView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Firma registrada',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu firma digital ha sido guardada correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Volver al perfil',
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
// CARD DE OPCIÓN (Subir imagen / Dibujar firma)
// ════════════════════════════════════════════════════════════════════════════
class _OpcionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OpcionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
