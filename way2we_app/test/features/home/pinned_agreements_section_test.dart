import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/app/view/app.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/home/view/home_page.dart';
import 'package:way2we_app/l10n/l10n.dart';

class FakeAgreementProvider extends AgreementProvider {
  FakeAgreementProvider() : super(dio: Dio());

  int listCalls = 0;

  @override
  Future<List<Agreement>> listAgreements({
    required int groupId,
    String? status,
  }) async {
    listCalls += 1;
    return [
      Agreement(
        id: 1,
        name: 'Pinned',
        points: 5,
        requireConfirmation: true,
        status: AgreementStatus.active,
        groupId: groupId,
        creatorId: 1,
        applicableMemberIds: const [],
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        isPinned: true,
      ),
    ];
  }
}

class _TestHome extends StatelessWidget {
  const _TestHome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        body: Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Next'),
              );
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('PinnedAgreementsSection refreshes when route resumes', (
    tester,
  ) async {
    final provider = FakeAgreementProvider();

    await tester.pumpWidget(
      RepositoryProvider<AgreementProvider>.value(
        value: provider,
        child: MaterialApp(
          navigatorObservers: [routeObserver],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _TestHome(
            child: PinnedAgreementsSection(groupId: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(provider.listCalls, 1);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(provider.listCalls, 2);
  });
}
