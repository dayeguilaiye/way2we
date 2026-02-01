part of 'redemption_detail_bloc.dart';

sealed class RedemptionDetailEvent extends Equatable {
  const RedemptionDetailEvent();

  @override
  List<Object?> get props => [];
}

final class LoadOrderDetail extends RedemptionDetailEvent {
  const LoadOrderDetail({required this.groupId, required this.orderId});

  final int groupId;
  final int orderId;

  @override
  List<Object?> get props => [groupId, orderId];
}

final class RefreshOrderDetail extends RedemptionDetailEvent {
  const RefreshOrderDetail();
}

final class FulfillOrderRequested extends RedemptionDetailEvent {
  const FulfillOrderRequested();
}

final class ConfirmOrderRequested extends RedemptionDetailEvent {
  const ConfirmOrderRequested();
}

final class MarkUnsatisfiedRequested extends RedemptionDetailEvent {
  const MarkUnsatisfiedRequested({this.reason});

  final String? reason;

  @override
  List<Object?> get props => [reason];
}
