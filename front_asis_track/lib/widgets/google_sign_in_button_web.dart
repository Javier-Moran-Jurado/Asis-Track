// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../themes/app_theme.dart';
import 'dart:ui_web' as ui_web;

/// Botón de Google Sign-In para Flutter Web usando GIS renderButton.
///
/// Renderiza el botón oficial de Google Sign-In a través de HtmlElementView,
/// evitando problemas con popups bloqueados por COOP.
/// El callback se define en index.html (handleCredentialResponse).
class GoogleSignInButtonWeb extends StatefulWidget {
  const GoogleSignInButtonWeb({super.key});

  @override
  State<GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<GoogleSignInButtonWeb> {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    html.window.addEventListener(
      'google-signin-success',
      _handleEvent,
    );
  }

  @override
  void dispose() {
    html.window.removeEventListener(
      'google-signin-success',
      _handleEvent,
    );
    super.dispose();
  }

  void _handleEvent(html.Event event) {
    if (_processing) return;
    final token = js.context['googleIdToken'] as String?;
    if (token != null && token.isNotEmpty) {
      _processToken(token);
    }
  }

  Future<void> _processToken(String idToken) async {
    if (_processing) return;
    _processing = true;

    if (!mounted) {
      _processing = false;
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    try {
      final user = await GoogleAuthService.authenticateWithIdToken(idToken);
      if (!mounted) return;
      auth.setUser(user);
      // Limpiar el token usado para evitar re-procesamiento
      js.context['googleIdToken'] = null;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _processing = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static bool _factoryRegistered = false;

  @override
  Widget build(BuildContext context) {
    const viewType = 'google-signin-btn';
    if (!_factoryRegistered) {
      _factoryRegistered = true;
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final div = html.DivElement()
          ..id = 'g_id_signin_$viewId'
          ..style.width = '100%'
          ..style.height = '100%';

        void render() {
          final google = js.context['google'];
          if (google == null || google['accounts'] == null) {
            html.window.requestAnimationFrame((_) => render());
            return;
          }
          final id = google['accounts']['id'];
          if (id == null) return;
          id.callMethod('renderButton', [
            div,
            js.JsObject.jsify({
              'theme': 'outline',
              'size': 'large',
              'width': div.clientWidth > 0 ? div.clientWidth : 300,
              'text': 'signin_with',
            }),
          ]);
        }

        html.window.requestAnimationFrame((_) => render());
        return div;
      });
    }

    return Center(
      child: SizedBox(
        height: 48,
        width: 300,
        child: const HtmlElementView(viewType: viewType),
      ),
    );
  }
}
