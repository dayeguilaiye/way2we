import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('W2WButton shows loading state and blocks taps', (tester) async {
    var tapCount = 0;

    await tester.pumpApp(
      Scaffold(
        body: W2WButton(
          label: 'Save',
          isLoading: true,
          onPressed: () {
            tapCount += 1;
          },
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(W2WButton));
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('W2WButton respects reduced-motion settings', (tester) async {
    await tester.pumpApp(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: W2WButton(
            label: 'Save',
            isLoading: true,
          ),
        ),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('W2WInput renders label and hint', (tester) async {
    await tester.pumpApp(
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: W2WInput(
            label: 'Email',
            hintText: 'you@example.com',
          ),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('W2WInput supports suffix and max length', (tester) async {
    await tester.pumpApp(
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: W2WInput(
            label: 'Points',
            suffixText: 'pts',
            maxLength: 3,
          ),
        ),
      ),
    );

    expect(find.text('Points'), findsOneWidget);
    expect(find.text('pts'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('W2WCard handles tap callback', (tester) async {
    var tapped = false;

    await tester.pumpApp(
      Scaffold(
        body: W2WCard(
          onTap: () {
            tapped = true;
          },
          child: const Text('Card'),
        ),
      ),
    );

    await tester.tap(find.text('Card'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('W2WStatusBadge renders status label', (tester) async {
    await tester.pumpApp(
      const Scaffold(
        body: W2WStatusBadge(
          label: 'Completed',
          type: W2WStatusType.completed,
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('W2WEmptyState action button triggers callback', (tester) async {
    var tapped = false;

    await tester.pumpApp(
      Scaffold(
        body: W2WEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No data',
          actionLabel: 'Retry',
          onAction: () {
            tapped = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
