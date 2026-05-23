import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:front_asis_track/routes/app_router.dart';
import 'package:front_asis_track/services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  AuthService.onUnauthorized = authProvider.logout;

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<StudentProvider>(
            create: (_) => StudentProvider(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          title: 'AsisTrack',
          routerConfig: createAppRouter(authProvider),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
