part of 'redemption_detail_bloc.dart';

enum RedemptionDetailAction { fulfill, confirm, unsatisfied }

sealed class RedemptionDetailState extends Equatable {
  const RedemptionDetailState();

  @override
  List<Object?> get props => [];
}

final class RedemptionDetailInitial extends RedemptionDetailState {
  const RedemptionDetailInitial();
}

final class RedemptionDetailLoading extends RedemptionDetailState {
  const RedemptionDetailLoading();
}

sealed class RedemptionDetailReadyState extends RedemptionDetailState {
  const RedemptionDetailReadyState({
    required this.order,
    required this.groupId,
  });

  final RedemptionOrder order;
  final int groupId;

  @override
  List<Object?> get props => [order, groupId];
}

final class RedemptionDetailLoaded extends RedemptionDetailReadyState {
  const RedemptionDetailLoaded({
    required super.order,
    required super.groupId,
  });
}

final class RedemptionDetailActionSuccess extends RedemptionDetailReadyState {
  const RedemptionDetailActionSuccess({
    required super.order,
    required super.groupId,
    required this.action,
  });

  final RedemptionDetailAction action;

  @override
  List<Object?> get props => [order, groupId, action];
}

final class RedemptionDetailActionFailure extends RedemptionDetailReadyState {
  const RedemptionDetailActionFailure({
    required super.order,
    required super.groupId,
    required this.message,
    this.code,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => [order, groupId, message, code];
}

final class RedemptionDetailError extends RedemptionDetailState {
  const RedemptionDetailError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
