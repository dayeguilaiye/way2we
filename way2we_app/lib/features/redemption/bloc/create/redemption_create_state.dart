part of 'redemption_create_bloc.dart';

enum RedemptionCreateStatus { initial, submitting, success, failure }

class RedemptionCreateState extends Equatable {
  const RedemptionCreateState({
    this.status = RedemptionCreateStatus.initial,
    this.order,
    this.message,
    this.code,
  });

  final RedemptionCreateStatus status;
  final RedemptionOrder? order;
  final String? message;
  final String? code;

  RedemptionCreateState copyWith({
    RedemptionCreateStatus? status,
    RedemptionOrder? order,
    String? message,
    String? code,
  }) {
    return RedemptionCreateState(
      status: status ?? this.status,
      order: order ?? this.order,
      message: message,
      code: code,
    );
  }

  @override
  List<Object?> get props => [status, order, message, code];
}
