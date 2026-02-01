part of 'redemption_create_bloc.dart';

sealed class RedemptionCreateEvent extends Equatable {
  const RedemptionCreateEvent();

  @override
  List<Object?> get props => [];
}

final class SubmitRedemption extends RedemptionCreateEvent {
  const SubmitRedemption({
    required this.groupId,
    required this.rewardId,
    required this.quantity,
  });

  final int groupId;
  final int rewardId;
  final int quantity;

  @override
  List<Object?> get props => [groupId, rewardId, quantity];
}
