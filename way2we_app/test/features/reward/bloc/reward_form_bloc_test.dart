import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/features/reward/bloc/form/reward_form_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

class MockRewardProvider extends Mock implements RewardProvider {}

class MockGroupProvider extends Mock implements GroupProvider {}

void main() {
  late RewardProvider rewardProvider;
  late GroupProvider groupProvider;

  setUpAll(() {
    registerFallbackValue(
      const CreateRewardInput(name: 'Fallback', costPoints: 1),
    );
  });

  setUp(() {
    rewardProvider = MockRewardProvider();
    groupProvider = MockGroupProvider();
  });

  Reward buildReward() {
    return Reward(
      id: 1,
      name: 'Reward',
      description: 'Desc',
      costPoints: 10,
      status: RewardStatus.active,
      autoFulfill: true,
      autoComplete: false,
      groupId: 1,
      providerId: 2,
      providerNickname: 'Alice',
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );
  }

  blocTest<RewardFormBloc, RewardFormState>(
    'initializes defaults from group settings',
    build: () {
      when(
        () => groupProvider.getGroupSettings(groupId: 1),
      ).thenAnswer(
        (_) async => const GroupSettings(
          requireConfirmationDefault: true,
          autoCompleteRedemptionDefault: true,
          autoFulfillRedemptionDefault: false,
          providerIncentiveRatio: 0,
        ),
      );
      return RewardFormBloc(
        rewardProvider: rewardProvider,
        groupProvider: groupProvider,
      );
    },
    act: (bloc) => bloc.add(const InitializeForm(groupId: 1)),
    expect: () => [
      const RewardFormState(
        autoFulfill: false,
        autoComplete: true,
        costPoints: 10,
      ),
    ],
  );

  blocTest<RewardFormBloc, RewardFormState>(
    'submits create reward successfully',
    build: () {
      when(
        () => groupProvider.getGroupSettings(groupId: 1),
      ).thenAnswer(
        (_) async => const GroupSettings(
          requireConfirmationDefault: true,
          autoCompleteRedemptionDefault: false,
          autoFulfillRedemptionDefault: false,
          providerIncentiveRatio: 0,
        ),
      );
      when(
        () => rewardProvider.createReward(
          groupId: 1,
          input: any(named: 'input'),
        ),
      ).thenAnswer((_) async => buildReward());
      return RewardFormBloc(
        rewardProvider: rewardProvider,
        groupProvider: groupProvider,
      );
    },
    act: (bloc) {
      bloc.add(const InitializeForm(groupId: 1));
      bloc.add(const NameChanged('Reward'));
      bloc.add(const SubmitReward(groupId: 1));
    },
    expect: () => [
      const RewardFormState(
        autoFulfill: false,
        autoComplete: false,
        costPoints: 10,
      ),
      const RewardFormState(
        name: 'Reward',
        autoFulfill: false,
        autoComplete: false,
        costPoints: 10,
      ),
      const RewardFormState(
        name: 'Reward',
        costPoints: 10,
        autoFulfill: false,
        autoComplete: false,
        status: RewardFormStatus.submitting,
      ),
      const RewardFormState(
        name: 'Reward',
        costPoints: 10,
        autoFulfill: false,
        autoComplete: false,
        status: RewardFormStatus.success,
      ),
    ],
  );

  blocTest<RewardFormBloc, RewardFormState>(
    'emits failure when create reward fails',
    build: () {
      when(
        () => groupProvider.getGroupSettings(groupId: 1),
      ).thenAnswer(
        (_) async => const GroupSettings(
          requireConfirmationDefault: true,
          autoCompleteRedemptionDefault: false,
          autoFulfillRedemptionDefault: false,
          providerIncentiveRatio: 0,
        ),
      );
      when(
        () => rewardProvider.createReward(
          groupId: 1,
          input: any(named: 'input'),
        ),
      ).thenThrow(const RewardApiException('Create failed', code: 'ERR_CREATE'));
      return RewardFormBloc(
        rewardProvider: rewardProvider,
        groupProvider: groupProvider,
      );
    },
    act: (bloc) {
      bloc.add(const InitializeForm(groupId: 1));
      bloc.add(const NameChanged('Reward'));
      bloc.add(const SubmitReward(groupId: 1));
    },
    expect: () => [
      const RewardFormState(
        autoFulfill: false,
        autoComplete: false,
        costPoints: 10,
      ),
      const RewardFormState(
        name: 'Reward',
        autoFulfill: false,
        autoComplete: false,
        costPoints: 10,
      ),
      const RewardFormState(
        name: 'Reward',
        costPoints: 10,
        autoFulfill: false,
        autoComplete: false,
        status: RewardFormStatus.submitting,
      ),
      const RewardFormState(
        name: 'Reward',
        costPoints: 10,
        autoFulfill: false,
        autoComplete: false,
        status: RewardFormStatus.failure,
        errorMessage: 'Create failed',
        errorCode: 'ERR_CREATE',
      ),
    ],
  );

  test('canSubmit is false when points invalid', () {
    const state = RewardFormState(name: 'Reward', costPoints: 0);
    expect(state.canSubmit, isFalse);
  });
}
