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
import 'package:front_asis_track/views/justificaciones/justificacion_screen.dart';
import 'package:front_asis_track/views/firma/firma_screen.dart';
import 'package:front_asis_track/views/planillas/planillas_screen.dart';
import 'package:front_asis_track/views/planillas/crear_planilla_screen.dart';
import 'package:front_asis_track/views/planillas/llenar_planilla_screen.dart';
import 'package:front_asis_track/views/planillas/formulario_invitado_screen.dart';
import 'package:front_asis_track/views/planillas/dashboard_screen.dart';
import 'package:front_asis_track/views/planillas/digitalizar_planilla_screen.dart';
import 'package:front_asis_track/screens/event_list_screen.dart';
import 'package:front_asis_track/screens/digitization_screen.dart';
import 'package:front_asis_track/screens/preview_screen.dart';
import 'package:front_asis_track/screens/planilla_list_screen.dart';
import 'package:front_asis_track/views/perfil/perfil_screen.dart';
import 'package:front_asis_track/views/usuarios/usuarios_screen.dart';
import 'package:front_asis_track/views/eventos/eventos_screen.dart';
import 'package:front_asis_track/views/lugares/lugares_screen.dart';
import 'package:front_asis_track/models/evento_qr.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

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
    // ── DIGITALIZACIÓN DE PLANILLAS ──
    GoRoute(
      path: '/',
      builder: (context, state) => const EventListScreen(),
    ),
    GoRoute(
      path: '/digitize/:eventId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final eventId = state.pathParameters['eventId'] ?? '';
        return DigitizationScreen(
          eventId: eventId,
          eventName: '',
        );
      },
    ),
    GoRoute(
      path: '/preview/:eventId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PreviewScreen(),
    ),

    // ── DETALLES (FUERA DEL SHELL) ──
    GoRoute(
      name: 'h_detalle',
      path: '/h-detalle',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        key: const ValueKey('key_h_detalle'),
        child: HistorialDetalleScreen(
            asistencia: state.extra as HistorialAsistencia),
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
    GoRoute(
      name: 'j_nueva',
      path: '/justificaciones/nueva',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => MaterialPage(
        key: const ValueKey('key_j_nueva'),
        child: JustificacionScreen(
            asistencia: state.extra as HistorialAsistencia),
      ),
    ),
    GoRoute(
      path: '/firma',
      builder: (context, state) => const FirmaScreen(),
    ),
    GoRoute(
      path: '/planillas/nueva',
      builder: (context, state) => CrearPlanillaScreen(planillaId: state.extra as int?),
    ),
    GoRoute(
      path: '/formulario/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return FormularioInvitadoScreen(planillaId: id);
      },
    ),
    GoRoute(
      path: '/planillas/llenar',
      builder: (context, state) => LlenarPlanillaScreen(planillaId: state.extra as int),
    ),
    GoRoute(
      path: '/planilla-digital/eventos',
      builder: (context, state) => const EventListScreen(),
    ),
    GoRoute(
      path: '/planilla-digital/digitizar',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return DigitizationScreen(
          eventId: data['id']?.toString() ?? '',
          eventName: data['nombre']?.toString() ?? 'Evento',
        );
      },
    ),
    GoRoute(
      path: '/planilla-digital/preview',
      builder: (context, state) => const PreviewScreen(),
    ),
    GoRoute(
      path: '/planillas/digitalizar',
      builder: (context, state) => const DigitalizarPlanillaScreen(),
    ),
    GoRoute(
      path: '/planillas/digitalizar/preview/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return DigitalizarPreviewScreen(planillaId: id);
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/mis-planillas',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PlanillaListScreen(),
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
          path: '/planillas',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_planillas'),
            child: PlanillasScreen(),
          ),
        ),
        GoRoute(
          path: '/perfil',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_perfil'),
            child: PerfilScreen(),
          ),
        ),
        GoRoute(
          path: '/usuarios',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_usuarios'),
            child: UsuariosScreen(),
          ),
        ),
        GoRoute(
          path: '/eventos',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_eventos'),
            child: EventosScreen(),
          ),
        ),
        GoRoute(
          path: '/lugares',
          pageBuilder: (context, state) => const NoTransitionPage(
            key: ValueKey('key_lugares'),
            child: LugaresScreen(),
          ),
        ),
      ],
    ),
  ],
);
