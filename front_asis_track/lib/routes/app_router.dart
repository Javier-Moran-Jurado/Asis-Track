import 'package:front_asis_track/views/asistencia/asistencia_detalle_screen.dart';
import 'package:front_asis_track/views/asistencia/asistencia_home_screen.dart';
import 'package:front_asis_track/views/asistencia/qr_scanner_screen.dart';
import 'package:front_asis_track/views/asistencia/qr_generator_screen.dart';
import 'package:front_asis_track/views/auth/login_screen.dart';
import 'package:front_asis_track/views/auth/register_screen.dart';
import 'package:front_asis_track/views/home/home_screen.dart';
import 'package:front_asis_track/views/main_layout.dart';
import 'package:front_asis_track/views/justificaciones/justificaciones_screen.dart';
import 'package:front_asis_track/views/paso_parametros/detalle_screen.dart';
import 'package:front_asis_track/views/paso_parametros/paso_parametros_screen.dart';
import 'package:front_asis_track/views/perfil/perfil_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../models/evento_qr.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // ── Autenticación ─────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login',
    ),

    // ── Shell Route para el Layout Principal (Bottom Navbar) ──────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/justificaciones',
          builder: (context, state) => const JustificacionesScreen(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const PerfilScreen(),
        ),
        GoRoute(
          path: '/asistencia',
          builder: (context, state) => const AsistenciaHomeScreen(),
          routes: [
            GoRoute(
              path: 'escaner',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const QrScannerScreen(),
            ),
            GoRoute(
              path: 'generador',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const QrGeneratorScreen(),
            ),
            GoRoute(
              path: 'detalle',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final evento = state.extra as EventoQr;
                return AsistenciaDetalleScreen(evento: evento);
              },
            ),
          ],
        ),
      ],
    ),

    // ── Paso de parámetros (ejemplo) ─────────────────────────────────────
    GoRoute(
      path: '/paso_parametros',
      builder: (context, state) => const PasoParametrosScreen(),
    ),
    GoRoute(
      path: '/detalle/:parametro/:metodo',
      builder: (context, state) {
        final parametro = state.pathParameters['parametro']!;
        final metodo = state.pathParameters['metodo']!;
        return DetalleScreen(parametro: parametro, metodoNavegacion: metodo);
      },
    ),
  ],
);
