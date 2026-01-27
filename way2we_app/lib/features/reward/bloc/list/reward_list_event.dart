part of 'reward_list_bloc.dart';

sealed class RewardListEvent extends Equatable {
  const RewardListEvent();

  @override
  List<Object?> get props => [];
}

final class LoadRewards extends RewardListEvent {
  const LoadRewards({required this.groupId, this.statusFilter});

  final int groupId;
  final String? statusFilter;

  @override
  List<Object?> get props => [groupId, statusFilter];
}

final class RefreshRewards extends RewardListEvent {
  const RefreshRewards();
}

final class UpdateRewardStatus extends RewardListEvent {
  const UpdateRewardStatus({
    required this.rewardId,
    required this.newStatus,
  });

  final int rewardId;
  final String newStatus;

  @override
  List<Object?> get props => [rewardId, newStatus];
}
