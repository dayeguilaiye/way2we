part of 'redemption_list_bloc.dart';

sealed class RedemptionListState extends Equatable {
  const RedemptionListState();

  @override
  List<Object?> get props => [];
}

final class RedemptionListInitial extends RedemptionListState {
  const RedemptionListInitial();
}

final class RedemptionListLoading extends RedemptionListState {
  const RedemptionListLoading();
}

sealed class RedemptionListReadyState extends RedemptionListState {
  const RedemptionListReadyState({
    required this.orders,
    required this.groupId,
    this.status,
    this.role,
  });

  final List<RedemptionOrder> orders;
  final int groupId;
  final String? status;
  final String? role;

  @override
  List<Object?> get props => [orders, groupId, status, role];
}

final class RedemptionListLoaded extends RedemptionListReadyState {
  const RedemptionListLoaded({
    required super.orders,
    required super.groupId,
    super.status,
    super.role,
  });
}

final class RedemptionListError extends RedemptionListState {
  const RedemptionListError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
