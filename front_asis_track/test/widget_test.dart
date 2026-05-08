import 'package:flutter_test/flutter_test.dart';
import 'package:front_asis_track/providers/auth_provider.dart';
import 'package:front_asis_track/main.dart';

void main() {
  testWidgets('App smoke test — la app arranca sin errores',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
