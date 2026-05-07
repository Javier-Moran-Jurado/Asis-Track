import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:front_asis_track/views/asistencia/asistencia_detalle_screen.dart';
import 'package:front_asis_track/views/asistencia/asistencia_home_screen.dart';
import 'package:front_asis_track/views/asistencia/qr_scanner_screen.dart';
import 'package:front_asis_track/views/asistencia/qr_generator_screen.dart';
import 'package:front_asis_track/views/auth/login_screen.dart';
import 'package:front_asis_track/views/auth/register_screen.dart';
import 'package:front_asis_track/views/home/home_screen.dart';
import 'package:front_asis_track/views/historial/historial_screen.dart';
import 'package:front_asis_track/views/historial/historial_detalle_screen.dart';
import 'package:front_asis_track/models/historial_asistencia.dart';
import 'package:front_asis_track/views/main_layout.dart';
import 'package:front_asis_track/views/justificaciones/justificaciones_screen.dart';
import 'package:front_asis_track/views/perfil/perfil_screen.dart';
import 'package:front_asis_track/models/evento_qr.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  debugLogDiagnostics: true,
  routes: [
    // ── AUTH ──
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ── DETALLES (FUERA DEL SHELL) ──
    GoRoute(
      name: 'h_detalle',
      path: '/h-detalle',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        key: const ValueKey('key_h_detalle'),
        child: HistorialDetalleScreen(asistencia: state.extra as HistorialAsistencia),
      ),
    ),
    GoRoute(
      name: 'a_detalle',
      path: '/a-detalle',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        key: const ValueKey('key_a_detalle'),
        child: AsistenciaDetalleScreen(evento: state.extra as EventoQr),
      ),
    ),
    GoRoute(
      path: '/a-escaner',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        key: ValueKey('key_a_escaner'),
        child: QrScannerScreen(),
      ),
    ),
    GoRoute(
      path: '/a-generador',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const MaterialPage(
        key: ValueKey('key_a_generador'),
        child: QrGeneratorScreen(),
      ),
    ),

    // ── MAIN SHELL ──
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_home'),
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/asistencia',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_asistencia'),
            child: AsistenciaHomeScreen(),
          ),
        ),
        GoRoute(
          path: '/historial',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_historial'),
            child: HistorialScreen(),
          ),
        ),
        GoRoute(
          path: '/justificaciones',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_justificaciones'),
            child: JustificacionesScreen(),
          ),
        ),
        GoRoute(
          path: '/perfil',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_perfil'),
            child: PerfilScreen(),
          ),
        ),
      ],
    ),
  ],
);
