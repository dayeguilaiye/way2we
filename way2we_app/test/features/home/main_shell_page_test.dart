import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';

import '../../helpers/pump_app.dart';

class MockGroupControlBloc
    extends MockBloc<GroupControlEvent, GroupControlState>
    implements GroupControlBloc {}

class FakeAgreementProvider extends AgreementProvider {
  FakeAgreementProvider() : super(dio: Dio());

  @override
  Future<List<Agreement>> listAgreements({
    required int groupId,
    String? status,
  }) async {
    return [];
  }
}

class FakeRewardProvider extends RewardProvider {
  FakeRewardProvider() : super(dio: Dio());

  @override
  Future<List<Reward>> listRewards({
    required int groupId,
    String? status,
    bool pinnedOnly = false,
  }) async {
    return [];
  }
}

class FakeRedemptionProvider extends RedemptionProvider {
  FakeRedemptionProvider() : super(dio: Dio());

  @override
  Future<List<RedemptionOrder>> listOrders({
    required int groupId,
    String? status,
    String? role,
    int? limit,
    int? offset,
  }) async {
    return [];
  }
}

void main() {
  late MockGroupControlBloc groupControlBloc;

  const group = UserGroup(
    id: 1,
    name: 'Family Group',
    memberCount: 2,
    role: 'admin',
    permissions: ['create_agreement'],
    joinedAt: '2024-01-01T00:00:00Z',
    createdAt: '2024-01-01T00:00:00Z',
  );

  const successState = GroupControlLoadSuccess(
    groups: [group],
    selectedGroup: group,
  );

  setUp(() {
    groupControlBloc = MockGroupControlBloc();
    when(() => groupControlBloc.state).thenReturn(successState);
    whenListen(
      groupControlBloc,
      Stream<GroupControlState>.value(successState),
      initialState: successState,
    );
  });

  tearDown(() async {
    await groupControlBloc.close();
  });

  Widget buildTestWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AgreementProvider>(
          create: (_) => FakeAgreementProvider(),
        ),
        RepositoryProvider<AgreementCompletionProvider>(
          create: (_) => AgreementCompletionProvider(dio: Dio()),
        ),
        RepositoryProvider<RewardProvider>(create: (_) => FakeRewardProvider()),
        RepositoryProvider<RedemptionProvider>(
          create: (_) => FakeRedemptionProvider(),
        ),
      ],
      child: BlocProvider<GroupControlBloc>.value(
        value: groupControlBloc,
        child: const MainShellPage(),
      ),
    );
  }

  Finder destinationFinder(String label) {
    return find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
  }

  testWidgets('renders four tab destinations', (tester) async {
    await tester.pumpApp(buildTestWidget());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));
    final l10n = AppLocalizations.of(context);

    expect(destinationFinder(l10n.homeTabTitle), findsOneWidget);
    expect(destinationFinder(l10n.agreementTabTitle), findsOneWidget);
    expect(destinationFinder(l10n.rewardTabTitle), findsOneWidget);
    expect(destinationFinder(l10n.redemptionOrderTabTitle), findsOneWidget);
  });

  testWidgets('keeps agreement tab inner state when switching tabs', (
    tester,
  ) async {
    await tester.pumpApp(buildTestWidget());
    await tester.pumpAndSettle();

    final navContext = tester.element(find.byType(NavigationBar));
    final l10n = AppLocalizations.of(navContext);

    await tester.tap(destinationFinder(l10n.agreementTabTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.agreementStatusInactive));
    await tester.pumpAndSettle();

    var tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 1);

    await tester.tap(destinationFinder(l10n.rewardTabTitle));
    await tester.pumpAndSettle();

    await tester.tap(destinationFinder(l10n.agreementTabTitle));
    await tester.pumpAndSettle();

    tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 1);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, MainTab.agreements.index);
  });
}
