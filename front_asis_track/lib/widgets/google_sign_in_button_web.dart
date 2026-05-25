// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
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
/// Usa google.accounts.id.prompt() (GIS One Tap) con `use_fedcm_for_prompt: false`
/// para evitar el polling infinito en Chrome 120+.
/// Si el prompt es suprimido, cae al flujo OAuth2 popup clásico.
class GoogleSignInButtonWeb extends StatefulWidget {
  const GoogleSignInButtonWeb({super.key});

  @override
  State<GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<GoogleSignInButtonWeb> {
  StreamSubscription<html.Event>? _sub;
  bool _isLoading = false;

  /// Guard: evita que múltiples llamadas concurrentes procesen el mismo token.
  bool _processing = false;

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

  // ── Manejador del evento que dispara handleCredentialResponse en index.html ─

  void _handleSuccess(html.Event event) {
    if (_processing) return; // Ignorar llamadas duplicadas
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
    setState(() => _isLoading = true);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Acción al pulsar el botón ───────────────────────────────────────────────

  void _signIn() {
    if (_processing) return;

    final google = js.context['google'];
    if (google == null) {
      _showError('Google Identity Services no está disponible. Recarga la página.');
      return;
    }

    final id = google['accounts']?['id'];
    if (id == null) {
      _showError('No se pudo inicializar Google Sign-In. Recarga la página.');
      return;
    }

    // Limpiar token anterior para evitar que _handleSuccess use uno viejo
    js.context['googleIdToken'] = null;

    // Usamos prompt() con un moment_listener para detectar si fue bloqueado.
    // El listener se envuelve en try/catch porque GIS lo llama en contexto JS.
    id.callMethod('prompt', [
      js.JsFunction.withThis((self, notification) {
        try {
          // isNotDisplayed() → el prompt no se mostró (bloqueado por navegador)
          final notDisplayed =
              notification.callMethod('isNotDisplayed') as bool? ?? false;
          // isSkippedMoment() → el prompt fue suprimido por GIS automáticamente
          final skipped =
              notification.callMethod('isSkippedMoment') as bool? ?? false;

          if (notDisplayed || skipped) {
            // El One Tap fue bloqueado → intentar popup clásico
            _fallbackOAuth2Popup(google['accounts']!);
          }
        } catch (_) {
          // Si el moment_listener falla, ignorar silenciosamente
        }
      }),
    ]);
  }

  /// Popup OAuth2 clásico como fallback cuando One Tap es bloqueado.
  void _fallbackOAuth2Popup(js.JsObject accounts) {
    if (_processing) return;

    final oauth2 = accounts['oauth2'];
    if (oauth2 == null) {
      _showError(
        'El navegador bloqueó el inicio de sesión con Google. '
        'Permite ventanas emergentes e inténtalo de nuevo.',
      );
      return;
    }

    _processing = true;

    // Usamos un Completer para manejar el callback del token de forma segura.
    // El Completer garantiza que solo se completa UNA vez aunque el callback
    // se llame varias veces (previniendo "Future already completed").
    final completer = Completer<String?>();

    final tokenClient = oauth2.callMethod('initTokenClient', [
      js.JsObject.jsify({
        'client_id':
            '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com',
        'scope': 'openid email profile',
        'callback': js.JsFunction.withThis((self, tokenResponse) {
          if (completer.isCompleted) return;
          final idToken = tokenResponse['id_token']?.toString();
          completer.complete(idToken);
        }),
        'error_callback': js.JsFunction.withThis((self, error) {
          if (completer.isCompleted) return;
          final type = error['type']?.toString() ?? 'unknown';
          completer.complete(null); // Completa con null para indicar error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (type == 'popup_closed') {
              _showError('Cerraste la ventana de Google antes de completar el inicio de sesión.');
            } else if (type == 'popup_failed_to_open') {
              _showError(
                'El navegador bloqueó la ventana emergente de Google. '
                'Permite ventanas emergentes e inténtalo de nuevo.',
              );
            } else {
              _showError('Error al iniciar sesión con Google: $type');
            }
          });
        }),
      }),
    ]);

    // Esperar el token de forma asíncrona con seguridad
    tokenClient?.callMethod('requestAccessToken', [
      js.JsObject.jsify({'prompt': 'select_account'}),
    ]);

    completer.future.then((idToken) {
      if (idToken != null && idToken.isNotEmpty) {
        js.context['googleIdToken'] = idToken;
        _processToken(idToken);
      } else {
        _processing = false;
        if (mounted) setState(() => _isLoading = false);
      }
    }).catchError((_) {
      _processing = false;
      if (mounted) setState(() => _isLoading = false);
    });
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
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
