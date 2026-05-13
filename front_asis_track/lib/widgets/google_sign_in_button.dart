import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../themes/app_theme.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _signInMobile() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else if (auth.errorMessage != null) {
      _showErrorSnackBar(auth.errorMessage!);
    }
    setState(() => _isLoading = false);
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
    if (kIsWeb) {
      return const GoogleSignInButtonWeb();
    }

    // Mobile: botón tradicional
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInMobile,
      icon: Image.network(
        'https://www.google.com/favicon.ico',
        height: 20,
        width: 20,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.account_circle, size: 20),
      ),
      label: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Iniciar sesión con Google',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}
