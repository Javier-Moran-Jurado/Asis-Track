import 'package:flutter/material.dart';

/// Breakpoints reutilizables para responsive design.
///
/// Uso:
/// ```dart
/// if (AppBreakpoints.isMobile(context)) { ... }
/// ```
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  /// Ancho máximo para formularios y contenido centrado.
  static const double maxContentWidth = 600;

  /// Padding adaptativo según breakpoint.
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  /// Cantidad de columnas en un grid adaptativo.
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }
}
