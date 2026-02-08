part of 'reward_list_bloc.dart';

sealed class RewardListState extends Equatable {
  const RewardListState();

  @override
  List<Object?> get props => [];
}

final class RewardListInitial extends RewardListState {
  const RewardListInitial();
}

final class RewardListLoading extends RewardListState {
  const RewardListLoading();
}

sealed class RewardListReadyState extends RewardListState {
  const RewardListReadyState({
    required this.rewards,
    required this.groupId,
    required this.statusFilter,
  });

  final List<Reward> rewards;
  final int groupId;
  final String? statusFilter;

  bool get isActiveFilter => statusFilter == null || statusFilter == 'active';

  @override
  List<Object?> get props => [rewards, groupId, statusFilter];
}

final class RewardListLoaded extends RewardListReadyState {
  const RewardListLoaded({
    required super.rewards,
    required super.groupId,
    super.statusFilter,
  });
}

final class RewardListActionSuccess extends RewardListReadyState {
  const RewardListActionSuccess({
    required super.rewards,
    required super.groupId,
    required this.updatedStatus,
    super.statusFilter,
  });

  final String updatedStatus;

  @override
  List<Object?> get props => super.props..addAll([updatedStatus]);
}

final class RewardListActionFailure extends RewardListReadyState {
  const RewardListActionFailure({
    required super.rewards,
    required super.groupId,
    required this.message,
    super.statusFilter,
    this.code,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => super.props..addAll([message, code]);
}

final class RewardListError extends RewardListState {
  const RewardListError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
