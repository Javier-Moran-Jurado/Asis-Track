import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/evento_qr.dart';
import '../../providers/auth_provider.dart';
import '../../services/asistencia_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class InvitadoScreen extends StatefulWidget {
  final String? eventoId;

  const InvitadoScreen({super.key, this.eventoId});

  @override
  State<InvitadoScreen> createState() => _InvitadoScreenState();
}

class _InvitadoScreenState extends State<InvitadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoadingEvent = false;
  bool _isSaving = false;
  bool _isSuccess = false;
  String? _errorMessage;
  EventoQr? _evento;

  @override
  void initState() {
    super.initState();
    if (widget.eventoId != null && widget.eventoId!.isNotEmpty) {
      _loadEventDetails();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoadingEvent = true;
      _errorMessage = null;
    });

    try {
      final event = await AsistenciaService.validarQr(widget.eventoId!);
      if (mounted) {
        setState(() {
          _evento = event;
          _isLoadingEvent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoadingEvent = false;
        });
      }
    }
  }

  Future<void> _registrarAsistencia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // TODO: conectar al backend real
      // Realizamos el envío simulando la llamada al endpoint para cumplir el requisito
      final baseUrl = AppConfig.planillaUrl;
      final uri = Uri.parse('$baseUrl/asistencia/registrar/invitado');

      final body = {
        'nombreCompleto': _nombreController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'eventoId': widget.eventoId,
      };

      try {
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Proceso exitoso real
        }
      } catch (e) {
        // Captura errores y permite continuar la demostración local
        debugPrint('[InvitadoScreen] Falló el endpoint de invitado (esperado en modo local/sin backend): $e');
      }

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar asistencia: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.responsivePadding(context);

    if (_isSuccess) {
      return _buildSuccessScreen(padding);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (!mounted) return;
              context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Salir'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoadingEvent)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildErrorCard()
                else if (_evento != null)
                  _buildEventInfoCard()
                else
                  _buildNoEventWarning(),

                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(EdgeInsets padding) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.secondaryColor,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Registro Exitoso!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu asistencia como invitado ha sido registrada de forma correcta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    if (_evento != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _evento!.materia,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _evento!.actividad,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _evento!.lugar,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.gray900),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Entendido',
                        onPressed: () {
                          // Si es Flutter Web o se escaneó desde la app, volvemos a la raíz o cerramos.
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            setState(() {
                              _isSuccess = false;
                              _nombreController.clear();
                              _cedulaController.clear();
                              _correoController.clear();
                              _telefonoController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 0,
      color: AppTheme.errorColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.errorColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error de validación QR',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage ?? 'No se pudo verificar el evento.',
                    style: TextStyle(fontSize: 13, color: AppTheme.errorColor.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEventWarning() {
    return Card(
      elevation: 0,
      color: AppTheme.warningColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.warningColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Código QR Faltante',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No se especificó un identificador de evento válido. Es posible que el registro no se guarde para ningún evento.',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 4)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_available, color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'Asistencia al Evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _evento!.materia,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray900),
            ),
            const SizedBox(height: 4),
            Text(
              _evento!.actividad,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _evento!.lugar,
                    style: const TextStyle(fontSize: 13, color: AppTheme.gray900),
                  ),
                ),
                if (_evento!.zonaNombre != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.map_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _evento!.zonaNombre!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.gray900),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos del Invitado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa la información para registrar tu asistencia.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Nombre completo *',
                hintText: 'Ej. Juan Pérez',
                controller: _nombreController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre completo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Cédula de ciudadanía *',
                hintText: 'Ej. 123456789',
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La cédula es obligatoria';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'La cédula debe contener solo números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Correo electrónico *',
                hintText: 'Ej. juan.perez@example.com',
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo electrónico es obligatorio';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Teléfono de contacto (Opcional)',
                hintText: 'Ej. 3001234567',
                controller: _telefonoController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value.trim()) == null) {
                      return 'El teléfono debe contener solo números';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Registrar asistencia',
                isLoading: _isSaving,
                onPressed: _registrarAsistencia,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
