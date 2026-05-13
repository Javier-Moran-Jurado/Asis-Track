import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../themes/app_theme.dart';

/// Registra el HtmlElementView factory para el botón GIS.
void registerFactory() {
  ui.platformViewRegistry.registerViewFactory(
    'google-signin-btn',
    (int viewId) {
      final div = html.DivElement()
        ..id = 'gsi-btn-$viewId'
        ..style.width = '100%'
        ..style.height = '100%';

      void tryRender() {
        final google = js.context['google'];
        if (google != null) {
          final accounts = google['accounts'];
          if (accounts != null) {
            final id = accounts['id'];
            if (id != null) {
              id.callMethod('renderButton', [
                div,
                js.JsObject.jsify({
                  'theme': 'outline',
                  'size': 'large',
                  'width': 360,
                  'text': 'signin_with',
                })
              ]);
              return;
            }
          }
        }
        html.window.requestAnimationFrame((_) => tryRender());
      }

      html.window.requestAnimationFrame((_) => tryRender());
      return div;
    },
  );
}

/// Botón de Google Sign-In para Flutter Web usando GIS nativo.
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
    if (token != null && token.isNotEmpty) {
      _processToken(token);
    }
  }

  Future<void> _processToken(String idToken) async {
    if (_isLoading) return;

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
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const HtmlElementView(viewType: 'google-signin-btn'),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
