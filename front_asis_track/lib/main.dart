import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:front_asis_track/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'themes/app_theme.dart';
import 'widgets/google_sign_in_button_web.dart'
    if (dart.library.io) 'widgets/google_sign_in_button_stub.dart' as gsi;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  if (kIsWeb) {
    gsi.registerFactory();
  }

  // Verificar si hay una sesión activa antes de renderizar la primera pantalla.
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        title: 'Asis-Track',
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
