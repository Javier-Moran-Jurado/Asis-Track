import 'package:flutter/foundation.dart';

class RoleService {
  // Roles: 'estudiante', 'profesor/monitor'
  static final ValueNotifier<String> currentRole = ValueNotifier<String>('estudiante');

  static bool get isProfesorOrMonitor => currentRole.value == 'profesor/monitor';
}
