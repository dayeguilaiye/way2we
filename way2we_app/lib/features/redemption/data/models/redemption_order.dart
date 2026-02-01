import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redemption_order.g.dart';

/// Redemption order status enum.
enum RedemptionOrderStatus {
  @JsonValue('awaiting_fulfill')
  awaitingFulfill,
  @JsonValue('awaiting_confirm')
  awaitingConfirm,
  @JsonValue('completed')
  completed,
  @JsonValue('unsatisfied')
  unsatisfied,
}

/// Redemption order model.
@JsonSerializable()
class RedemptionOrder extends Equatable {
  const RedemptionOrder({
    required this.id,
    required this.groupId,
    required this.rewardId,
    required this.consumerId,
    required this.providerId,
    required this.quantity,
    required this.unitCostPoints,
    required this.totalCostPoints,
    required this.status,
    required this.autoFulfill,
    required this.autoComplete,
    required this.providerIncentiveRatio,
    required this.createdAt,
    required this.updatedAt,
    this.rewardName,
    this.consumerNickname,
    this.providerNickname,
    this.fulfilledAt,
    this.confirmedAt,
    this.endedAt,
    this.unsatisfiedReason,
  });

  factory RedemptionOrder.fromJson(Map<String, dynamic> json) =>
      _$RedemptionOrderFromJson(json);

  final int id;
  @JsonKey(name: 'group_id')
  final int groupId;
  @JsonKey(name: 'reward_id')
  final int rewardId;
  @JsonKey(name: 'reward_name')
  final String? rewardName;
  @JsonKey(name: 'consumer_id')
  final int consumerId;
  @JsonKey(name: 'consumer_nickname')
  final String? consumerNickname;
  @JsonKey(name: 'provider_id')
  final int providerId;
  @JsonKey(name: 'provider_nickname')
  final String? providerNickname;
  final int quantity;
  @JsonKey(name: 'unit_cost_points')
  final int unitCostPoints;
  @JsonKey(name: 'total_cost_points')
  final int totalCostPoints;
  @JsonKey(unknownEnumValue: RedemptionOrderStatus.awaitingFulfill)
  final RedemptionOrderStatus status;
  @JsonKey(name: 'auto_fulfill')
  final bool autoFulfill;
  @JsonKey(name: 'auto_complete')
  final bool autoComplete;
  @JsonKey(name: 'provider_incentive_ratio')
  final int providerIncentiveRatio;
  @JsonKey(name: 'unsatisfied_reason')
  final String? unsatisfiedReason;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'fulfilled_at')
  final DateTime? fulfilledAt;
  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;

  Map<String, dynamic> toJson() => _$RedemptionOrderToJson(this);

  bool get isAwaitingFulfill => status == RedemptionOrderStatus.awaitingFulfill;
  bool get isAwaitingConfirm => status == RedemptionOrderStatus.awaitingConfirm;
  bool get isCompleted => status == RedemptionOrderStatus.completed;
  bool get isUnsatisfied => status == RedemptionOrderStatus.unsatisfied;

  @override
  List<Object?> get props => [
    id,
    groupId,
    rewardId,
    rewardName,
    consumerId,
    consumerNickname,
    providerId,
    providerNickname,
    quantity,
    unitCostPoints,
    totalCostPoints,
    status,
    autoFulfill,
    autoComplete,
    providerIncentiveRatio,
    unsatisfiedReason,
    createdAt,
    updatedAt,
    fulfilledAt,
    confirmedAt,
    endedAt,
  ];
}
