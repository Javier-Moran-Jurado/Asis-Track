import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

/// Estados posibles del flujo de autenticación.
enum AuthStatus {
  /// Estado inicial antes de verificar la sesión.
  initial,

  /// Verificando sesión o ejecutando login / logout.
  loading,

  /// El usuario tiene un token válido y datos de sesión.
  authenticated,

  /// Sin sesión activa (logout o primera ejecución).
  unauthenticated,

  /// Ocurrió un error durante el login.
  error,
}

/// Provider de autenticación.
///
/// Centraliza:
///   • El estado del flujo de auth (cargando / autenticado / error).
///   • La llamada al API de login y el manejo de tokens/datos.
///   • El logout con limpieza total de almacenamiento.
///
/// Uso en la UI:
/// ```dart
/// final auth = context.read<AuthProvider>();
/// await auth.login(codigo, contrasena);
/// ```
class AuthProvider extends ChangeNotifier {
  // ──────────────────────────────────────────────────────────────────────────
  // Estado interno
  // ──────────────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _currentUser;

  // ──────────────────────────────────────────────────────────────────────────
  // Getters públicos
  // ──────────────────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFICACIÓN DE SESIÓN AL INICIAR LA APP
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifica si existe un token válido en SecureStorage y carga los datos
  /// de usuario desde SharedPreferences.
  ///
  /// Llamar en `main()` antes de `runApp()` para que el estado inicial sea
  /// correcto desde el primer frame.
  Future<void> checkAuthStatus() async {
    final hasToken = await AuthService.hasValidToken();

    if (hasToken) {
      _currentUser = await AuthService.getUserFromPrefs();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════════════════

  /// Realiza el flujo completo de autenticación:
  ///
  /// 1. POST /api/v1/auth/login → obtiene access_token y refresh_token.
  /// 2. Decodifica el JWT para extraer `nombre_completo`, `rol` y `codigo`.
  /// 3. GET /api/v1/usuario-service/usuarios/{codigo} → obtiene `correo`.
  /// 4. Guarda tokens en **SecureStorage** (datos sensibles).
  /// 5. Guarda datos de usuario en **SharedPreferences** (datos no sensibles).
  ///
  /// Retorna `true` si el login fue exitoso, `false` en caso de error.
  /// El error queda disponible en [errorMessage].
  Future<bool> login(String codigo, String contrasena) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // ── 1. Llamada al API de login ─────────────────────────────────────
      final tokens = await AuthService.login(codigo, contrasena);
      final accessToken = tokens['access_token']!;
      final refreshToken = tokens['refresh_token']!;

      // ── 2. Decodificar JWT ─────────────────────────────────────────────
      final claims = AuthService.decodeJwtPayload(accessToken);
      //  El backend pone el código en el campo `jti` (JWT ID).
      final codigoFromToken = claims['jti']?.toString() ?? codigo;
      final nombreCompleto = claims['nombre_completo']?.toString() ?? '';
      final rol = claims['rol']?.toString() ?? '';

      // ── 3. Obtener correo desde el perfil del usuario ──────────────────
      String correo = '';
      try {
        final profile =
            await AuthService.getUserProfile(codigoFromToken, accessToken);
        correo = profile.correo;
      } catch (_) {
        // Si el perfil no se puede obtener, el correo queda vacío.
        // No interrumpimos el login por esto.
        debugPrint('[AuthProvider] No se pudo obtener el perfil del usuario.');
      }

      // ── 4. Guardar tokens en SecureStorage (SENSIBLE) ──────────────────
      await AuthService.saveTokens(accessToken, refreshToken);

      // ── 5. Guardar datos no sensibles en SharedPreferences ─────────────
      final user = UserModel(
        codigo: codigoFromToken,
        nombreCompleto: nombreCompleto,
        correo: correo,
        rol: rol,
      );
      await AuthService.saveUserData(user);

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIN WITH GOOGLE
  // ══════════════════════════════════════════════════════════════════════════

  /// Realiza el flujo completo de autenticacion con Google:
  Future<bool> loginWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await GoogleAuthService.signInWithGoogle();

      if (user == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  /// Cierra la sesión eliminando:
  ///   • `access_token` y `refresh_token` de SecureStorage.
  ///   • `nombre_completo`, `correo`, `codigo` y `rol` de SharedPreferences.
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await AuthService.clearAllStorage();

    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ══════════════════════════════════════════════════════════════════════════

  /// Limpia el mensaje de error sin cambiar el estado de autenticación.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Establece el usuario actual y pasa a estado autenticado.
  void setUser(UserModel user) {
    _currentUser = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
