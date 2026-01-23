import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/app/app.dart';
import 'package:way2we_app/features/auth/auth.dart';

void main() {
  group('App', () {
    testWidgets('renders LoginPage', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
