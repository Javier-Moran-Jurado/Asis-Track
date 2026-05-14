import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../themes/app_theme.dart';

/// Botón de Google Sign-In para Flutter Web usando GIS prompt (One Tap, sin popup).
class GoogleSignInButtonWeb extends StatefulWidget {
  const GoogleSignInButtonWeb({super.key});

  @override
  State<GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<GoogleSignInButtonWeb> {
  StreamSubscription? _sub;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sub = html.window.on['google-signin-success'].listen(_handleSuccess);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleSuccess(html.Event event) {
    final token = js.context['googleIdToken'] as String?;
    if (token != null && token.isNotEmpty && !_isLoading) {
      _processToken(token);
    }
  }

  Future<void> _processToken(String idToken) async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    auth.clearError();

    try {
      final user = await GoogleAuthService.authenticateWithIdToken(idToken);
      if (!mounted) return;
      auth.setUser(user);
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _signIn() {
    final google = js.context['google'];
    if (google != null) {
      final accounts = google['accounts'];
      if (accounts != null) {
        final id = accounts['id'];
        if (id != null) {
          id.callMethod('prompt');
          return;
        }
      }
    }
    _showError('Google Identity Services no está disponible. Recarga la página.');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signIn,
        icon: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.login, size: 20),
        label: const Text('Iniciar sesión con Google',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
