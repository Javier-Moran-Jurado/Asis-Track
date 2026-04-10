import 'package:front_asis_track/views/home/home_screen.dart';
import 'package:front_asis_track/views/paso_parametros/detalle_screen.dart';
import 'package:front_asis_track/views/paso_parametros/paso_parametros_screen.dart';
import 'package:go_router/go_router.dart';


final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(), // Usa HomeView
    ),
    // Rutas para el paso de parámetros
    GoRoute(
      path: '/paso_parametros',
      builder: (context, state) => const PasoParametrosScreen(),
    ),

    // !Ruta para el detalle con parámetros
    GoRoute(
      path:
          '/detalle/:parametro/:metodo', //la ruta recibe dos parametros los " : " indican que son parametros
      builder: (context, state) {
        //*se capturan los parametros recibidos
        // declarando las variables parametro y metodo
        // es final porque no se van a modificar
        final parametro = state.pathParameters['parametro']!;
        final metodo = state.pathParameters['metodo']!;
        return DetalleScreen(parametro: parametro, metodoNavegacion: metodo);
      },
    ),
    //!Ruta para el ciclo de vida
    // GoRoute(
    //   path: '/ciclo_vida',
    //   name: 'ciclo_vida',
    //   builder: (context, state) => const CicloVidaScreen(),
    // ),
  ],
);



