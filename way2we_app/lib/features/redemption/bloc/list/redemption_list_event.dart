part of 'redemption_list_bloc.dart';

sealed class RedemptionListEvent extends Equatable {
  const RedemptionListEvent();

  @override
  List<Object?> get props => [];
}

final class LoadOrders extends RedemptionListEvent {
  const LoadOrders({
    required this.groupId,
    this.status,
    this.role,
    this.limit,
    this.offset,
  });

  final int groupId;
  final String? status;
  final String? role;
  final int? limit;
  final int? offset;

  @override
  List<Object?> get props => [groupId, status, role, limit, offset];
}

final class RefreshOrders extends RedemptionListEvent {
  const RefreshOrders();
}
