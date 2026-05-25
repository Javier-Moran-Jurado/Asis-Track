import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../themes/app_theme.dart';

/// Botón de Google Sign-In para Flutter Web.
///
/// Estrategia: usa google.accounts.id.prompt() (One Tap / GIS).
/// Si el prompt es suprimido/bloqueado por el navegador, cae al flujo
/// de popup clásico (renderButton o token client) automáticamente.
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
    // Escucha el evento que dispara handleCredentialResponse en index.html
    _sub = html.window.on['google-signin-success'].listen(_handleSuccess);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Manejador de token recibido desde el callback GIS ──────────────────────

  void _handleSuccess(html.Event event) {
    final token = js.context['googleIdToken'] as String?;
    if (token != null && token.isNotEmpty && !_isLoading) {
      _processToken(token);
    }
  }

  Future<void> _processToken(String idToken) async {
    if (!mounted) return;
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

  // ── Flujo principal al pulsar el botón ─────────────────────────────────────

  void _signIn() {
    final google = js.context['google'];
    if (google == null) {
      _showError('Google Identity Services no está disponible. Recarga la página.');
      return;
    }

    final accounts = google['accounts'];
    if (accounts == null) {
      _showError('No se pudo inicializar Google. Recarga la página.');
      return;
    }

    final id = accounts['id'];
    if (id == null) {
      _showError('No se pudo inicializar Google Sign-In. Recarga la página.');
      return;
    }

    // Primero intentamos el prompt One Tap nativo.
    // Si el navegador lo suprime (skip_by_auto_cancel, user_cancel, etc.)
    // el callback moment_listener lo detecta y lanzamos el popup clásico.
    id.callMethod('prompt', [
      js.JsFunction.withThis((_, notification) {
        final reason = notification.callMethod('getSkippedReason')?.toString() ?? '';
        final dismissed = notification.callMethod('getDismissedReason')?.toString() ?? '';
        final notDisplayed = notification.callMethod('isNotDisplayed') as bool? ?? false;
        final skipped = notification.callMethod('isSkippedMoment') as bool? ?? false;
        final wasDismissed = notification.callMethod('isDismissedMoment') as bool? ?? false;

        // Si el One Tap fue bloqueado, suprimido o ignorado → popup clásico
        if (notDisplayed || skipped || wasDismissed) {
          _fallbackPopup(accounts, reason.isNotEmpty ? reason : dismissed);
        }
      }),
    ]);
  }

  /// Popup clásico usando google.accounts.oauth2 como fallback.
  void _fallbackPopup(js.JsObject accounts, String reason) {
    // Limpiar el token anterior para evitar re-uso
    js.context['googleIdToken'] = null;

    final oauth2 = accounts['oauth2'];
    if (oauth2 == null) {
      // Si oauth2 tampoco está disponible, usar el renderButton como último recurso
      _showError(
        'El navegador bloqueó el popup de Google. '
        'Permite ventanas emergentes para este sitio e inténtalo de nuevo.',
      );
      return;
    }

    // Solicitar un code/token mediante popup
    final tokenClient = oauth2.callMethod('initTokenClient', [
      js.JsObject.jsify({
        'client_id': '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com',
        'scope': 'openid email profile',
        'callback': js.JsFunction.withThis((_, tokenResponse) {
          // El token de acceso de OAuth2 no es un ID token, pero podemos
          // usar el id_token si viene incluido en la respuesta.
          final idToken = tokenResponse['id_token']?.toString();
          if (idToken != null && idToken.isNotEmpty) {
            js.context['googleIdToken'] = idToken;
            html.window.dispatchEvent(html.Event('google-signin-success'));
          } else {
            // Fallback: solicitar el ID token vía openid
            _showError(
              'No se recibió el token de identidad. '
              'Asegúrate de permitir ventanas emergentes e inténtalo de nuevo.',
            );
          }
        }),
        'error_callback': js.JsFunction.withThis((_, error) {
          final type = error['type']?.toString() ?? 'unknown';
          if (type == 'popup_closed') {
            _showError('Cerraste la ventana de Google antes de completar el inicio de sesión.');
          } else if (type == 'popup_failed_to_open') {
            _showError(
              'El navegador bloqueó la ventana emergente de Google. '
              'Permite ventanas emergentes para este sitio e inténtalo de nuevo.',
            );
          } else {
            _showError('Error al iniciar sesión con Google: $type');
          }
        }),
      }),
    ]);

    tokenClient?.callMethod('requestAccessToken', [
      js.JsObject.jsify({'prompt': 'select_account'}),
    ]);
  }

  // ── Error UI ───────────────────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signIn,
        icon: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login, size: 20),
        label: const Text(
          'Iniciar sesión con Google',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
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
