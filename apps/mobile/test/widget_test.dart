import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/theme.dart';
import 'package:way2we/features/diagnostics/presentation/diagnostics_page.dart';

void main() {
  testWidgets('theme changes preserve the form, large text stays scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: buildTheme(ref.watch(themeProvider)),
            home: const DiagnosticsPage(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('quantity')), '12');
    container.read(themeProvider.notifier).select(AppTheme.celadon);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('检查通用错误'));
    expect(tester.takeException(), isNull);
  });
}
