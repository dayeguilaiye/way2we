import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/group/view/create_group_page.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/group/view/join_group_page.dart';
import 'package:way2we_app/shared/widgets/w2w_card.dart';

import '../../../helpers/pump_app.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    ServiceLocator.instance.reset();
    ServiceLocator.instance.init();
  });

  tearDown(ServiceLocator.instance.reset);

  group('GroupSelectionPage', () {
    testWidgets('renders two selection cards', (tester) async {
      await tester.pumpApp(const GroupSelectionPage());

      expect(find.byType(W2WCard), findsNWidgets(2));
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.group_add_outlined), findsOneWidget);
    });

    testWidgets('navigates to create group page', (tester) async {
      final observer = _MockNavigatorObserver();
      when(() => observer.didPush(any(), any())).thenReturn(null);

      await tester.pumpApp(
        const GroupSelectionPage(),
        navigatorObservers: [observer],
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGroupPage), findsOneWidget);
    });

    testWidgets('navigates to join group page', (tester) async {
      final observer = _MockNavigatorObserver();
      when(() => observer.didPush(any(), any())).thenReturn(null);

      await tester.pumpApp(
        const GroupSelectionPage(),
        navigatorObservers: [observer],
      );

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(JoinGroupPage), findsOneWidget);
    });
  });
}
