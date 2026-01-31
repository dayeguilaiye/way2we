part of 'reward_list_bloc.dart';

sealed class RewardListEvent extends Equatable {
  const RewardListEvent();

  @override
  List<Object?> get props => [];
}

final class LoadRewards extends RewardListEvent {
  const LoadRewards({
    required this.groupId,
    this.statusFilter,
    this.pinnedOnly = false,
  });

  final int groupId;
  final String? statusFilter;
  final bool pinnedOnly;

  @override
  List<Object?> get props => [groupId, statusFilter, pinnedOnly];
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

final class PinRewardRequested extends RewardListEvent {
  const PinRewardRequested({required this.rewardId});

  final int rewardId;

  @override
  List<Object?> get props => [rewardId];
}

final class UnpinRewardRequested extends RewardListEvent {
  const UnpinRewardRequested({required this.rewardId});

  final int rewardId;

  @override
  List<Object?> get props => [rewardId];
}
