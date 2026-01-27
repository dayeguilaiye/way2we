import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/widgets/agreement_card.dart';
import 'package:way2we_app/l10n/l10n.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Agreement buildAgreement({required bool isPinned}) {
    return Agreement(
      id: 1,
      name: 'Test Agreement',
      points: 10,
      requireConfirmation: true,
      status: AgreementStatus.active,
      groupId: 1,
      creatorId: 1,
      applicableMemberIds: const [],
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      isPinned: isPinned,
      description: 'Desc',
    );
  }

  testWidgets('calls onTogglePin when pin icon tapped', (tester) async {
    var tapped = false;
    final agreement = buildAgreement(isPinned: false);

    await tester.pumpApp(
      AgreementCard(
        agreement: agreement,
        onTogglePin: () {
          tapped = true;
        },
      ),
    );

    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('shows long-press menu and triggers pin action', (tester) async {
    var tapped = false;
    final agreement = buildAgreement(isPinned: false);

    await tester.pumpApp(
      AgreementCard(
        agreement: agreement,
        onTogglePin: () {
          tapped = true;
        },
      ),
    );

    await tester.longPress(find.byType(AgreementCard));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AgreementCard));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.agreementPinAction), findsOneWidget);
    expect(find.text(l10n.cancel), findsOneWidget);

    await tester.tap(find.text(l10n.agreementPinAction));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
