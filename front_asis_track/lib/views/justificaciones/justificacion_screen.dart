import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/historial_asistencia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/justificacion_provider.dart';
import '../../services/justificacion_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class JustificacionScreen extends StatefulWidget {
  final HistorialAsistencia asistencia;

  const JustificacionScreen({super.key, required this.asistencia});

  @override
  State<JustificacionScreen> createState() => _JustificacionScreenState();
}

class _JustificacionScreenState extends State<JustificacionScreen> {
  late final JustificacionProvider _provider;
  late final TextEditingController _descripcionController;
  final GlobalKey _firmaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _provider = JustificacionProvider();
    _descripcionController = TextEditingController();
    _descripcionController.addListener(() {
      _provider.setDescripcion(_descripcionController.text);
    });
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Motivos disponibles
  // ──────────────────────────────────────────────────────────────────────────
  static const List<String> _motivos = [
    'Enfermedad',
    'Calamidad doméstica',
    'Cita médica',
    'Problema de transporte',
    'Otro',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nombre = auth.currentUser?.nombreCompleto ?? 'Estudiante';

    return ChangeNotifierProvider<JustificacionProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          titleSpacing: 16,
          title: const Text('Justificación'),
          centerTitle: false,
        ),
        body: Consumer<JustificacionProvider>(
          builder: (context, prov, _) {
            if (prov.isSuccess) {
              return _buildSuccessView(context, nombre);
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth),
                child: SingleChildScrollView(
              padding: AppBreakpoints.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  _buildHeader(nombre),
                  const SizedBox(height: 24),

                  // ── Datos de la inasistencia ─────────────────────────────
                  _buildInasistenciaCard(),
                  const SizedBox(height: 24),

                  // ── Motivo ───────────────────────────────────────────────
                  _buildMotivoDropdown(prov),
                  const SizedBox(height: 24),

                  // ── Descripción ───────────────────────────────────────────
                  _buildDescripcionField(),
                  const SizedBox(height: 24),

                  // ── Documentos adjuntos ───────────────────────────────────
                  _buildArchivoSection(prov),
                  const SizedBox(height: 24),

                  // ── Firma ─────────────────────────────────────────────────
                  _buildFirmaSection(prov),
                  const SizedBox(height: 32),

                  // ── Botones ───────────────────────────────────────────────
                  _buildBotones(prov),
                ],
              ),
            ),
            ),
          );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(String nombre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Justificación de inasistencias',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TARJETA DE INASISTENCIA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInasistenciaCard() {
    final fecha = DateFormat('EEEE, d MMMM yyyy', 'es')
        .format(widget.asistencia.fecha);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_outlined,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asistencia.materia,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fecha,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                widget.asistencia.docente,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 14, color: Color(0xFFB45309)),
                    SizedBox(width: 6),
                    Text(
                      'Pendiente de justificación',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DROPDOWN MOTIVO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMotivoDropdown(JustificacionProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Motivo de la ausencia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: prov.motivo,
            hint: const Text(
              'Selecciona un motivo',
              style: TextStyle(color: Colors.grey),
            ),
            items: _motivos.map((m) {
              return DropdownMenuItem<String>(
                value: m,
                child: Text(m),
              );
            }).toList(),
            onChanged: prov.setMotivo,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESCRIPCIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDescripcionField() {
    return CustomTextField(
      label: 'Descripción detallada',
      hintText: 'Describe el motivo de tu inasistencia...',
      controller: _descripcionController,
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ARCHIVOS ADJUNTOS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildArchivoSection(JustificacionProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos adjuntos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 8),
        if (prov.archivo != null)
          _buildArchivoPreview(prov)
        else
          _buildArchivoSelector(prov),
      ],
    );
  }

  Widget _buildArchivoSelector(JustificacionProvider prov) {
    return InkWell(
      onTap: () async {
        final archivo = await JustificacionService.seleccionarArchivo();
        if (archivo != null && context.mounted) {
          prov.setArchivo(archivo);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1.5),
            left: BorderSide(color: Colors.grey.shade300, width: 1.5),
            right: BorderSide(color: Colors.grey.shade300, width: 1.5),
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          // Líneas punteadas simuladas con borde normal
          // (DashedBorder requeriría paquete adicional, se usa borde sólido sutil)
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Selecciona un archivo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Formatos: PDF, JPG, PNG',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoPreview(JustificacionProvider prov) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf,
                color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prov.archivo!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Archivo adjunto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: prov.limpiarArchivo,
            icon:
                const Icon(Icons.close, color: AppTheme.errorColor, size: 20),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIRMA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFirmaSection(JustificacionProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Firma de respaldo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 8),
        // Toggle: dibujar / subir imagen
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => prov.setTipoFirma(TipoFirma.dibujo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: prov.tipoFirma == TipoFirma.dibujo
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: prov.tipoFirma == TipoFirma.dibujo
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Dibujar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => prov.setTipoFirma(TipoFirma.imagen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: prov.tipoFirma == TipoFirma.imagen
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: prov.tipoFirma == TipoFirma.imagen
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Subir imagen',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Contenido según tipo seleccionado
        if (prov.tipoFirma == TipoFirma.dibujo)
          _buildFirmaDibujo(prov)
        else
          _buildFirmaImagen(prov),
      ],
    );
  }

  Widget _buildFirmaDibujo(JustificacionProvider prov) {
    return Column(
      children: [
        Container(
          key: _firmaKey,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box =
                  _firmaKey.currentContext!.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              prov.agregarFirma(localPosition);
            },
            onPanEnd: (_) => prov.nuevaLineaFirma(),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _FirmaPainter(firmas: prov.firmas),
                    size: Size.infinite,
                  ),
                ),
                if (prov.firmas.isEmpty)
                  const Center(
                    child: Text(
                      'Firma aquí con tu dedo',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: prov.limpiarFirma,
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('Limpiar firma'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const Spacer(),
            if (prov.hasFirma)
              const Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.secondaryColor, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Firma registrada',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirmaImagen(JustificacionProvider prov) {
    if (prov.imagenFirma != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image,
                  color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prov.imagenFirma!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.gray900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Imagen de firma',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => prov.setImagenFirma(null),
              icon: const Icon(Icons.close,
                  color: AppTheme.errorColor, size: 20),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final imagen = await JustificacionService.seleccionarImagenFirma();
        if (imagen != null && context.mounted) {
          prov.setImagenFirma(imagen);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Subir imagen de la firma',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Formatos: JPG, PNG',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTONES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBotones(JustificacionProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prov.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          ),
        if (prov.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              prov.errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        CustomButton(
          text: 'Enviar justificación',
          isPrimary: true,
          isLoading: prov.isLoading,
          onPressed: prov.isFormValid && !prov.isLoading
              ? () async {
                  await prov.enviar(
                    onSubmit: JustificacionService.enviarJustificacion,
                    asistenciaId: widget.asistencia.id,
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Cancelar',
          isPrimary: false,
          isLoading: false,
          onPressed: prov.isLoading ? null : () => context.pop(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VISTA DE ÉXITO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuccessView(BuildContext context, String nombre) {
    final fecha = DateFormat('EEEE, d MMMM yyyy', 'es')
        .format(widget.asistencia.fecha);

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
              'Justificación enviada',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu justificación para la falta del $fecha en ${widget.asistencia.materia} ha sido enviada correctamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Estado: Pendiente de revisión',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Volver al historial',
              isPrimary: true,
              onPressed: () => context.pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAINTER DE FIRMA
// ════════════════════════════════════════════════════════════════════════════
class _FirmaPainter extends CustomPainter {
  final List<List<Offset>> firmas;

  _FirmaPainter({required this.firmas});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gray900
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final linea in firmas) {
      if (linea.isEmpty) continue;
      final path = Path();
      path.moveTo(linea.first.dx, linea.first.dy);
      for (int i = 1; i < linea.length; i++) {
        path.lineTo(linea[i].dx, linea[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirmaPainter oldDelegate) => true;
}
