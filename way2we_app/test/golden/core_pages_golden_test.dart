import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/app/di.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/agreement/view/agreement_detail_page.dart';
import 'package:way2we_app/features/agreement/view/agreement_list_page.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';
import 'package:way2we_app/features/auth/bloc/verification_code_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/bloc/invitation_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/group/models/member.dart';
import 'package:way2we_app/features/group/view/create_group_page.dart';
import 'package:way2we_app/features/group/view/group_default_settings_page.dart';
import 'package:way2we_app/features/group/view/group_selection_page.dart';
import 'package:way2we_app/features/group/view/invitation_page.dart';
import 'package:way2we_app/features/group/view/join_group_page.dart';
import 'package:way2we_app/features/group/view/member_detail_page.dart';
import 'package:way2we_app/features/group/view/member_management_page.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_detail_page.dart';
import 'package:way2we_app/features/redemption/view/redemption_order_list_page.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';
import 'package:way2we_app/features/reward/view/reward_detail_page.dart';
import 'package:way2we_app/features/reward/view/reward_list_page.dart';
import 'package:way2we_app/features/splash/view/splash_page.dart';

import '../helpers/pump_app.dart';

class MockGroupControlBloc
    extends MockBloc<GroupControlEvent, GroupControlState>
    implements GroupControlBloc {}

class MockAuthProvider extends Mock implements AuthProvider {}

class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class FakeGroupProvider extends GroupProvider {
  FakeGroupProvider() : super(dio: Dio());

  final List<Map<String, dynamic>> _members = [
    {
      'id': 1,
      'user_id': 1,
      'nickname': 'Alex',
      'avatar_url': null,
      'role': 'admin',
      'permissions': <String>[],
      'joined_at': '2025-01-01T00:00:00Z',
    },
    {
      'id': 2,
      'user_id': 2,
      'nickname': 'Sam',
      'avatar_url': null,
      'role': 'member',
      'permissions': <String>['create_agreement'],
      'joined_at': '2025-01-02T00:00:00Z',
    },
  ];

  GroupSettings _settings = const GroupSettings(
    requireConfirmationDefault: true,
    autoCompleteRedemptionDefault: false,
    autoFulfillRedemptionDefault: false,
    providerIncentiveRatio: 50,
  );

  @override
  Future<List<Map<String, dynamic>>> listMembers({required int groupId}) async {
    return _members.map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<void> updateMemberRole({
    required int groupId,
    required int userId,
    required String role,
  }) async {
    final index = _members.indexWhere((m) => m['user_id'] == userId);
    if (index != -1) {
      _members[index] = {
        ..._members[index],
        'role': role,
      };
    }
  }

  @override
  Future<void> updateMemberPermissions({
    required int groupId,
    required int userId,
    required List<String> permissions,
  }) async {
    final index = _members.indexWhere((m) => m['user_id'] == userId);
    if (index != -1) {
      _members[index] = {
        ..._members[index],
        'permissions': permissions,
      };
    }
  }

  @override
  Future<InvitationResponse> getInvitationCode({required int groupId}) async {
    return const InvitationResponse(
      groupId: 1,
      invitationCode: 'ABC123',
      shareUrl: 'https://way2we.app/invite/ABC123',
    );
  }

  @override
  Future<InvitationResponse> refreshInvitationCode({
    required int groupId,
  }) async {
    return const InvitationResponse(
      groupId: 1,
      invitationCode: 'XYZ789',
      shareUrl: 'https://way2we.app/invite/XYZ789',
    );
  }

  @override
  Future<GroupSettings> getGroupSettings({required int groupId}) async {
    return _settings;
  }

  @override
  Future<GroupSettings> updateGroupSettings({
    required int groupId,
    required Map<String, dynamic> settings,
  }) async {
    return _settings = GroupSettings(
      requireConfirmationDefault:
          settings['require_confirmation_default'] as bool,
      autoCompleteRedemptionDefault:
          settings['auto_complete_redemption_default'] as bool,
      autoFulfillRedemptionDefault:
          settings['auto_fulfill_redemption_default'] as bool,
      providerIncentiveRatio: settings['provider_incentive_ratio'] as int,
    );
  }
}

class FakeAgreementProvider extends AgreementProvider {
  FakeAgreementProvider() : super(dio: Dio());

  @override
  Future<List<Agreement>> listAgreements({
    required int groupId,
    String? status,
  }) async {
    final agreements = <Agreement>[
      Agreement(
        id: 1,
        name: 'Morning greeting',
        points: 5,
        requireConfirmation: true,
        status: AgreementStatus.active,
        groupId: groupId,
        creatorId: 1,
        applicableMemberIds: const [],
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        isPinned: true,
        description: 'Say good morning before 9:00.',
      ),
      Agreement(
        id: 2,
        name: 'Read 20 minutes',
        points: 3,
        requireConfirmation: false,
        status: AgreementStatus.inactive,
        groupId: groupId,
        creatorId: 1,
        applicableMemberIds: const [2],
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      ),
    ];

    if (status == 'inactive') {
      return agreements.where((a) => !a.isActive).toList();
    }
    return agreements.where((a) => a.isActive).toList();
  }

  @override
  Future<Agreement> getAgreement({
    required int groupId,
    required int agreementId,
  }) async {
    final agreements = await listAgreements(groupId: groupId);
    return agreements.firstWhere((agreement) => agreement.id == agreementId);
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
    final rewards = <Reward>[
      Reward(
        id: 11,
        name: 'Movie night',
        costPoints: 40,
        status: RewardStatus.active,
        autoFulfill: false,
        autoComplete: false,
        groupId: groupId,
        providerId: 1,
        providerNickname: 'Alex',
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        isPinned: true,
        description: 'Choose the next family movie.',
      ),
      Reward(
        id: 12,
        name: 'Ice cream',
        costPoints: 20,
        status: RewardStatus.inactive,
        autoFulfill: false,
        autoComplete: false,
        groupId: groupId,
        providerId: 2,
        providerNickname: 'Sam',
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      ),
    ];

    Iterable<Reward> result = rewards;
    if (status == 'active') {
      result = result.where((reward) => reward.isActive);
    } else if (status == 'inactive') {
      result = result.where((reward) => !reward.isActive);
    }
    if (pinnedOnly) {
      result = result.where((reward) => reward.isPinned);
    }
    return result.toList();
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
    return [
      RedemptionOrder(
        id: 21,
        groupId: groupId,
        rewardId: 11,
        rewardName: 'Movie night',
        consumerId: 2,
        consumerNickname: 'Sam',
        providerId: 1,
        providerNickname: 'Alex',
        quantity: 1,
        unitCostPoints: 40,
        totalCostPoints: 40,
        status: RedemptionOrderStatus.awaitingFulfill,
        autoFulfill: false,
        autoComplete: false,
        providerIncentiveRatio: 50,
        createdAt: DateTime.parse('2025-01-02T12:30:00Z'),
        updatedAt: DateTime.parse('2025-01-02T12:30:00Z'),
      ),
      RedemptionOrder(
        id: 22,
        groupId: groupId,
        rewardId: 12,
        rewardName: 'Ice cream',
        consumerId: 2,
        consumerNickname: 'Sam',
        providerId: 1,
        providerNickname: 'Alex',
        quantity: 2,
        unitCostPoints: 20,
        totalCostPoints: 40,
        status: RedemptionOrderStatus.completed,
        autoFulfill: false,
        autoComplete: false,
        providerIncentiveRatio: 50,
        createdAt: DateTime.parse('2025-01-03T08:00:00Z'),
        updatedAt: DateTime.parse('2025-01-03T08:00:00Z'),
      ),
    ];
  }

  @override
  Future<RedemptionOrder> getOrderDetail({
    required int groupId,
    required int orderId,
  }) async {
    final orders = await listOrders(groupId: groupId);
    return orders.firstWhere((order) => order.id == orderId);
  }
}

const _group = UserGroup(
  id: 1,
  name: 'Family Group',
  memberCount: 2,
  role: 'admin',
  permissions: ['create_agreement'],
  joinedAt: '2025-01-01T00:00:00Z',
  createdAt: '2025-01-01T00:00:00Z',
);

final _member = GroupMember(
  id: 2,
  userId: 2,
  nickname: 'Sam',
  role: GroupRole.member,
  permissions: const ['create_agreement'],
  joinedAt: DateTime.parse('2025-01-02T00:00:00Z'),
);

const _groupState = GroupControlLoadSuccess(
  groups: [_group],
  selectedGroup: _group,
);

MockGroupControlBloc _createGroupBloc() {
  final bloc = MockGroupControlBloc();
  when(() => bloc.state).thenReturn(_groupState);
  whenListen(
    bloc,
    Stream<GroupControlState>.value(_groupState),
    initialState: _groupState,
  );
  return bloc;
}

Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpApp(child);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Core UI goldens', () {
    testWidgets('splash page', (tester) async {
      final authBloc = MockAuthenticationBloc();
      when(() => authBloc.state).thenReturn(const AuthenticationInitial());
      whenListen(
        authBloc,
        Stream<AuthenticationState>.value(const AuthenticationInitial()),
        initialState: const AuthenticationInitial(),
      );
      addTearDown(authBloc.close);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpApp(
        BlocProvider<AuthenticationBloc>.value(
          value: authBloc,
          child: const SplashPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/splash_page.png'),
      );
    });

    testWidgets('login page', (tester) async {
      final authProvider = MockAuthProvider();

      await _pumpPhone(
        tester,
        RepositoryProvider<AuthProvider>.value(
          value: authProvider,
          child: BlocProvider<VerificationCodeBloc>(
            create: (_) => VerificationCodeBloc(authProvider: authProvider),
            child: const AuthView(),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/login_page.png'),
      );
    });

    testWidgets('group selection page', (tester) async {
      await _pumpPhone(tester, const GroupSelectionPage());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/group_selection_page.png'),
      );
    });

    testWidgets('create group page', (tester) async {
      ServiceLocator.instance.reset();
      ServiceLocator.instance.init();
      addTearDown(ServiceLocator.instance.reset);

      await _pumpPhone(tester, const CreateGroupPage());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/create_group_page.png'),
      );
    });

    testWidgets('join group page', (tester) async {
      ServiceLocator.instance.reset();
      ServiceLocator.instance.init();
      addTearDown(ServiceLocator.instance.reset);

      await _pumpPhone(tester, const JoinGroupPage());

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/join_group_page.png'),
      );
    });

    testWidgets('member management page', (tester) async {
      await _pumpPhone(
        tester,
        RepositoryProvider<GroupProvider>(
          create: (_) => FakeGroupProvider(),
          child: const MemberManagementPage(
            groupId: 1,
            groupName: 'Family Group',
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/member_management_page.png'),
      );
    });

    testWidgets('member detail page', (tester) async {
      await _pumpPhone(
        tester,
        RepositoryProvider<GroupProvider>(
          create: (_) => FakeGroupProvider(),
          child: MemberDetailPage(
            groupId: 1,
            member: _member,
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/member_detail_page.png'),
      );
    });

    testWidgets('invitation page', (tester) async {
      final groupProvider = FakeGroupProvider();
      await _pumpPhone(
        tester,
        BlocProvider(
          create: (_) => InvitationBloc(
            groupProvider: groupProvider,
            groupId: 1,
          )..add(const InvitationLoadRequested()),
          child: const InvitationView(groupName: 'Family Group'),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/invitation_page.png'),
      );
    });

    testWidgets('group default settings page', (tester) async {
      await _pumpPhone(
        tester,
        RepositoryProvider<GroupProvider>(
          create: (_) => FakeGroupProvider(),
          child: const GroupDefaultSettingsPage(groupId: 1),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/group_default_settings_page.png'),
      );
    });

    testWidgets('main shell', (tester) async {
      final groupBloc = _createGroupBloc();
      addTearDown(groupBloc.close);

      await _pumpPhone(
        tester,
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AgreementProvider>(
              create: (_) => FakeAgreementProvider(),
            ),
            RepositoryProvider<AgreementCompletionProvider>(
              create: (_) => AgreementCompletionProvider(dio: Dio()),
            ),
            RepositoryProvider<RewardProvider>(
              create: (_) => FakeRewardProvider(),
            ),
            RepositoryProvider<RedemptionProvider>(
              create: (_) => FakeRedemptionProvider(),
            ),
          ],
          child: BlocProvider<GroupControlBloc>.value(
            value: groupBloc,
            child: const MainShellPage(),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/main_shell.png'),
      );
    });

    testWidgets('agreement list page', (tester) async {
      final groupBloc = _createGroupBloc();
      addTearDown(groupBloc.close);

      await _pumpPhone(
        tester,
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AgreementProvider>(
              create: (_) => FakeAgreementProvider(),
            ),
            RepositoryProvider<AgreementCompletionProvider>(
              create: (_) => AgreementCompletionProvider(dio: Dio()),
            ),
          ],
          child: BlocProvider<GroupControlBloc>.value(
            value: groupBloc,
            child: AgreementListPage(groupId: _group.id),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/agreement_list.png'),
      );
    });

    testWidgets('agreement detail page', (tester) async {
      final groupBloc = _createGroupBloc();
      addTearDown(groupBloc.close);

      await _pumpPhone(
        tester,
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AgreementProvider>(
              create: (_) => FakeAgreementProvider(),
            ),
          ],
          child: BlocProvider<GroupControlBloc>.value(
            value: groupBloc,
            child: const AgreementDetailPage(groupId: 1, agreementId: 1),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/agreement_detail_page.png'),
      );
    });

    testWidgets('reward list page', (tester) async {
      final groupBloc = _createGroupBloc();
      addTearDown(groupBloc.close);

      await _pumpPhone(
        tester,
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RewardProvider>(
              create: (_) => FakeRewardProvider(),
            ),
          ],
          child: BlocProvider<GroupControlBloc>.value(
            value: groupBloc,
            child: RewardListPage(groupId: _group.id),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/reward_list.png'),
      );
    });

    testWidgets('reward detail page', (tester) async {
      ServiceLocator.instance.reset();
      ServiceLocator.instance.init();
      addTearDown(ServiceLocator.instance.reset);

      final groupBloc = _createGroupBloc();
      addTearDown(groupBloc.close);

      final reward = Reward(
        id: 11,
        name: 'Movie night',
        costPoints: 40,
        status: RewardStatus.active,
        autoFulfill: false,
        autoComplete: false,
        groupId: 1,
        providerId: 1,
        providerNickname: 'Alex',
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        description: 'Choose the next family movie.',
      );

      await _pumpPhone(
        tester,
        BlocProvider<GroupControlBloc>.value(
          value: groupBloc,
          child: RewardDetailPage(groupId: 1, reward: reward),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/reward_detail_page.png'),
      );
    });

    testWidgets('redemption order list page', (tester) async {
      await _pumpPhone(
        tester,
        RepositoryProvider<RedemptionProvider>(
          create: (_) => FakeRedemptionProvider(),
          child: RedemptionOrderListPage(groupId: _group.id),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/redemption_order_list.png'),
      );
    });

    testWidgets('redemption order detail page', (tester) async {
      ServiceLocator.instance.reset();
      ServiceLocator.instance.init();
      addTearDown(ServiceLocator.instance.reset);

      await _pumpPhone(
        tester,
        RepositoryProvider<RedemptionProvider>(
          create: (_) => FakeRedemptionProvider(),
          child: const RedemptionOrderDetailPage(groupId: 1, orderId: 21),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/redemption_order_detail_page.png'),
      );
    });
  });
}
