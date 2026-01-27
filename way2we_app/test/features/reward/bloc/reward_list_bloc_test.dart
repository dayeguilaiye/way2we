import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/reward/bloc/list/reward_list_bloc.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';
import 'package:way2we_app/features/reward/data/providers/reward_provider.dart';

class MockRewardProvider extends Mock implements RewardProvider {}

void main() {
  late RewardProvider rewardProvider;
  late RewardListBloc bloc;

  setUp(() {
    rewardProvider = MockRewardProvider();
    bloc = RewardListBloc(rewardProvider: rewardProvider);
  });

  Reward buildReward({required RewardStatus status}) {
    return Reward(
      id: 1,
      name: 'Reward',
      description: 'Desc',
      costPoints: 10,
      status: status,
      autoFulfill: false,
      autoComplete: false,
      groupId: 1,
      providerId: 2,
      providerNickname: 'Alice',
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );
  }

  test('initial state is RewardListInitial', () {
    expect(bloc.state, equals(const RewardListInitial()));
  });

  blocTest<RewardListBloc, RewardListState>(
    'emits loaded when load rewards succeeds',
    build: () {
      when(
        () => rewardProvider.listRewards(groupId: 1, status: 'active'),
      ).thenAnswer((_) async => [buildReward(status: RewardStatus.active)]);
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active')),
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
      ),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits action success when update status succeeds',
    build: () {
      final activeReward = buildReward(status: RewardStatus.active);
      final inactiveReward = buildReward(status: RewardStatus.inactive);
      when(
        () => rewardProvider.listRewards(groupId: 1, status: 'active'),
      ).thenAnswer((_) async => [activeReward]);
      when(
        () => rewardProvider.updateRewardStatus(
          groupId: 1,
          rewardId: 1,
          status: 'inactive',
        ),
      ).thenAnswer((_) async => inactiveReward);
      return bloc;
    },
    act: (bloc) {
      bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active'));
      bloc.add(const UpdateRewardStatus(rewardId: 1, newStatus: 'inactive'));
    },
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
      ),
      RewardListActionSuccess(
        rewards: [],
        groupId: 1,
        statusFilter: 'active',
        updatedStatus: 'inactive',
      ),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits error when load rewards fails',
    build: () {
      when(
        () => rewardProvider.listRewards(groupId: 1, status: 'active'),
      ).thenThrow(const RewardApiException('Load failed', code: 'ERR_LOAD'));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active')),
    expect: () => [
      const RewardListLoading(),
      const RewardListError(message: 'Load failed', code: 'ERR_LOAD'),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits action failure when update status fails',
    build: () {
      final activeReward = buildReward(status: RewardStatus.active);
      when(
        () => rewardProvider.listRewards(groupId: 1, status: 'active'),
      ).thenAnswer((_) async => [activeReward]);
      when(
        () => rewardProvider.updateRewardStatus(
          groupId: 1,
          rewardId: 1,
          status: 'inactive',
        ),
      ).thenThrow(const RewardApiException('Update failed', code: 'ERR_UPDATE'));
      return bloc;
    },
    act: (bloc) {
      bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active'));
      bloc.add(const UpdateRewardStatus(rewardId: 1, newStatus: 'inactive'));
    },
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
      ),
      RewardListActionFailure(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
        message: 'Update failed',
        code: 'ERR_UPDATE',
      ),
    ],
  );
}
