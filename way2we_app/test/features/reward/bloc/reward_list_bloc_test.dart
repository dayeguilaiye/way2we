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

  Reward buildReward({
    required RewardStatus status,
    int id = 1,
    bool isPinned = false,
  }) {
    return Reward(
      id: id,
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
      isPinned: isPinned,
    );
  }

  test('initial state is RewardListInitial', () {
    expect(bloc.state, equals(const RewardListInitial()));
  });

  blocTest<RewardListBloc, RewardListState>(
    'emits loaded when load rewards succeeds',
    build: () {
      when(
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
      ).thenAnswer((_) async => [buildReward(status: RewardStatus.active)]);
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active')),
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
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
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
    act: (bloc) => bloc
      ..add(const LoadRewards(groupId: 1, statusFilter: 'active'))
      ..add(const UpdateRewardStatus(rewardId: 1, newStatus: 'inactive')),
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
      ),
      const RewardListActionSuccess(
        rewards: [],
        groupId: 1,
        statusFilter: 'active',
        updatedStatus: 'inactive',
      ),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits optimistic update when pin reward succeeds',
    build: () {
      final rewardA = buildReward(status: RewardStatus.active);
      final rewardB = buildReward(status: RewardStatus.active, id: 2);
      when(
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
      ).thenAnswer((_) async => [rewardA, rewardB]);
      when(
        () => rewardProvider.pinReward(groupId: 1, rewardId: 2),
      ).thenAnswer((_) async {});
      return bloc;
    },
    act: (bloc) => bloc
      ..add(const LoadRewards(groupId: 1, statusFilter: 'active'))
      ..add(const PinRewardRequested(rewardId: 2)),
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [
          buildReward(status: RewardStatus.active),
          buildReward(status: RewardStatus.active, id: 2),
        ],
        groupId: 1,
        statusFilter: 'active',
      ),
      RewardListLoaded(
        rewards: [
          buildReward(status: RewardStatus.active, id: 2, isPinned: true),
          buildReward(status: RewardStatus.active),
        ],
        groupId: 1,
        statusFilter: 'active',
      ),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits action failure when unpin reward fails',
    build: () {
      final pinnedReward = buildReward(
        status: RewardStatus.active,
        isPinned: true,
      );
      when(
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
      ).thenAnswer((_) async => [pinnedReward]);
      when(
        () => rewardProvider.unpinReward(groupId: 1, rewardId: 1),
      ).thenThrow(const RewardApiException('Unpin failed', code: 'ERR_UNPIN'));
      return bloc;
    },
    act: (bloc) => bloc
      ..add(const LoadRewards(groupId: 1, statusFilter: 'active'))
      ..add(const UnpinRewardRequested(rewardId: 1)),
    expect: () => [
      const RewardListLoading(),
      RewardListLoaded(
        rewards: [
          buildReward(status: RewardStatus.active, isPinned: true),
        ],
        groupId: 1,
        statusFilter: 'active',
      ),
      RewardListLoaded(
        rewards: [buildReward(status: RewardStatus.active)],
        groupId: 1,
        statusFilter: 'active',
      ),
      RewardListActionFailure(
        rewards: [
          buildReward(status: RewardStatus.active, isPinned: true),
        ],
        groupId: 1,
        statusFilter: 'active',
        message: 'Unpin failed',
        code: 'ERR_UNPIN',
      ),
    ],
  );

  blocTest<RewardListBloc, RewardListState>(
    'emits error when load rewards fails',
    build: () {
      when(
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
      ).thenThrow(const RewardApiException('Load failed', code: 'ERR_LOAD'));
      return bloc;
    },
    act: (bloc) =>
        bloc.add(const LoadRewards(groupId: 1, statusFilter: 'active')),
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
        () => rewardProvider.listRewards(
          groupId: 1,
          status: 'active',
        ),
      ).thenAnswer((_) async => [activeReward]);
      when(
        () => rewardProvider.updateRewardStatus(
          groupId: 1,
          rewardId: 1,
          status: 'inactive',
        ),
      ).thenThrow(
        const RewardApiException('Update failed', code: 'ERR_UPDATE'),
      );
      return bloc;
    },
    act: (bloc) => bloc
      ..add(const LoadRewards(groupId: 1, statusFilter: 'active'))
      ..add(const UpdateRewardStatus(rewardId: 1, newStatus: 'inactive')),
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
