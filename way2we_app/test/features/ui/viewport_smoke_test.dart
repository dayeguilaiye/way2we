import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';
import 'package:way2we_app/features/auth/bloc/verification_code_bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/auth/view/login_page.dart';
import 'package:way2we_app/features/group/bloc/group_control_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/home/view/main_shell_page.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';
import 'package:way2we_app/features/redemption/data/providers/redemption_provider.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

import '../../helpers/pump_app.dart';

class MockGroupControlBloc
    extends MockBloc<GroupControlEvent, GroupControlState>
    implements GroupControlBloc {}

class MockAuthProvider extends Mock implements AuthProvider {}

class FakeAgreementProvider extends AgreementProvider {
  FakeAgreementProvider() : super(dio: Dio());

  @override
  Future<List<Agreement>> listAgreements({
    required int groupId,
    String? status,
  }) async {
    return [
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
      ),
    ];
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
    return [
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
      ),
    ];
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

const _group = UserGroup(
  id: 1,
  name: 'Family Group',
  memberCount: 2,
  role: 'admin',
  permissions: ['create_agreement'],
  joinedAt: '2025-01-01T00:00:00Z',
  createdAt: '2025-01-01T00:00:00Z',
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

const _sizes = <Size>[
  Size(375, 812),
  Size(390, 844),
  Size(430, 932),
  Size(412, 915),
];

Future<void> _pumpAtSize(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpApp(child);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Viewport smoke tests', () {
    for (final size in _sizes) {
      testWidgets('login page fits ${size.width}x${size.height}', (
        tester,
      ) async {
        final authProvider = MockAuthProvider();

        await _pumpAtSize(
          tester,
          size,
          RepositoryProvider<AuthProvider>.value(
            value: authProvider,
            child: BlocProvider<VerificationCodeBloc>(
              create: (_) => VerificationCodeBloc(authProvider: authProvider),
              child: const AuthView(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('main shell fits ${size.width}x${size.height}', (
        tester,
      ) async {
        final groupBloc = _createGroupBloc();
        addTearDown(groupBloc.close);

        await _pumpAtSize(
          tester,
          size,
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

        expect(tester.takeException(), isNull);
      });
    }
  });
}
