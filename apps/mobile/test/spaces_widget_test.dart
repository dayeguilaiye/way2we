import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/theme.dart';
import 'package:way2we/features/spaces/application/space_controller.dart';
import 'package:way2we/features/spaces/presentation/space_widgets.dart';

class ReadyOperation extends OperationController {
  @override
  OperationState build() => const OperationState(ready: true);
}

void main() {
  testWidgets(
    'space form and share actions remain reachable at small width and large text',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Reuse real native form widgets with a ready command boundary; no remote calls.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [operationProvider.overrideWith(ReadyOperation.new)],
          child: MaterialApp(
            theme: buildTheme(AppTheme.apricot),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 667),
                textScaler: TextScaler.linear(1.6),
                viewInsets: EdgeInsets.only(bottom: 240),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: InviteShare(code: 'ABCDEFGHIJKLMNOPQRST'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('复制链接'));
      expect(find.text('复制链接'), findsOneWidget);
    },
  );
  test('name validation counts Unicode code points and trimmed emptiness', () {
    expect(nameError('   '), isNotNull);
    expect(nameError('昵称'), isNull);
    expect(nameError('名' * 61), isNotNull);
  });
}
