import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    // Limpiar errores previos
    auth.clearError();

    final success = await auth.login(
      _codigoController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      _showErrorSnackBar(auth.errorMessage ?? 'Error desconocido al iniciar sesión.');
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();

    // Limpiar errores previos
    auth.clearError();

    final success = await auth.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else if (auth.errorMessage != null) {
      _showErrorSnackBar(auth.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos solo isLoading para reconstruir el botón
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppBreakpoints.responsivePadding(context),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ───────────────────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/icon/logo_asis_track.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Asis-Track',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Universidad del Valle del Cauca',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // ── Encabezado del formulario ────────────────────────────
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu código institucional y contraseña.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // ── Campo: Código de usuario ─────────────────────────────
                  CustomTextField(
                    label: 'Código de usuario',
                    hintText: 'Ej. 2024117801',
                    controller: _codigoController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa tu código';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'El código debe ser un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Campo: Contraseña ────────────────────────────────────
                  CustomTextField(
                    label: 'Contraseña',
                    hintText: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Botón de ingreso ─────────────────────────────────────
                  CustomButton(
                    text: 'Ingresar',
                    onPressed: isLoading ? null : _login,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  // ── Botón de Google ──────────────────────────────────────
                  GoogleSignInButton(),
                  const SizedBox(height: 24),

                  // (Registro deshabilitado: solo roles autorizados pueden crear usuarios)
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
