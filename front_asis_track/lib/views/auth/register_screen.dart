import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRolId;
  bool _isLoading = false;

  final List<Map<String, String>> _roles = const [
    {'id': '1', 'nombre': 'Estudiante'},
    {'id': '2', 'nombre': 'Coordinador'},
    {'id': '3', 'nombre': 'Docente'},
    {'id': '4', 'nombre': 'Administrativo'},
    {'id': '5', 'nombre': 'Decano'},
    {'id': '6', 'nombre': 'Rector'},
    {'id': '7', 'nombre': 'Administrador'},
    {'id': '8', 'nombre': 'Monitor'},
    {'id': '9', 'nombre': 'Directivo'},
  ];

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRolId == null) {
      ErrorDialog.show(context, 'Por favor selecciona un rol');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ErrorDialog.show(context, 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserService.createUser(
        codigo: _studentIdController.text.trim(),
        nombreCompleto: _nameController.text.trim(),
        correo: _emailController.text.trim(),
        contrasena: _passwordController.text,
        cedula: _cedulaController.text.trim(),
        telefono: _telefonoController.text.trim(),
        rolId: _selectedRolId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado con éxito'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AsisTrack',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppBreakpoints.responsivePadding(context),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset(
                      'assets/icon/logo_asis_track.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crear usuario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solo usuarios autorizados pueden crear nuevas cuentas.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Nombre completo',
                    hintText: 'Juan Pérez',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Correo electrónico',
                    hintText: 'juan.perez@uceva.edu.co',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Código institucional',
                    hintText: '2024117801',
                    controller: _studentIdController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el código';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Cédula',
                    hintText: '1234567890',
                    controller: _cedulaController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la cédula';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Teléfono',
                    hintText: '3001234567',
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el teléfono';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRolId,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    hint: const Text('Selecciona un rol'),
                    items: _roles.map((rol) {
                      return DropdownMenuItem<String>(
                        value: rol['id'],
                        child: Text(rol['nombre']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRolId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona un rol';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la contraseña';
                      }
                      if (value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirmar contraseña',
                    hintText: 'Repite la contraseña',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma la contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Crear usuario',
                    onPressed: _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
