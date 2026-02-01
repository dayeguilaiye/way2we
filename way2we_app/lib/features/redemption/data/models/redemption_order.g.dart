// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redemption_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedemptionOrder _$RedemptionOrderFromJson(Map<String, dynamic> json) =>
    RedemptionOrder(
      id: (json['id'] as num).toInt(),
      groupId: (json['group_id'] as num).toInt(),
      rewardId: (json['reward_id'] as num).toInt(),
      consumerId: (json['consumer_id'] as num).toInt(),
      providerId: (json['provider_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitCostPoints: (json['unit_cost_points'] as num).toInt(),
      totalCostPoints: (json['total_cost_points'] as num).toInt(),
      status: $enumDecode(
        _$RedemptionOrderStatusEnumMap,
        json['status'],
        unknownValue: RedemptionOrderStatus.awaitingFulfill,
      ),
      autoFulfill: json['auto_fulfill'] as bool,
      autoComplete: json['auto_complete'] as bool,
      providerIncentiveRatio:
          (json['provider_incentive_ratio'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      rewardName: json['reward_name'] as String?,
      consumerNickname: json['consumer_nickname'] as String?,
      providerNickname: json['provider_nickname'] as String?,
      fulfilledAt: json['fulfilled_at'] == null
          ? null
          : DateTime.parse(json['fulfilled_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      unsatisfiedReason: json['unsatisfied_reason'] as String?,
    );

Map<String, dynamic> _$RedemptionOrderToJson(RedemptionOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'reward_id': instance.rewardId,
      'reward_name': instance.rewardName,
      'consumer_id': instance.consumerId,
      'consumer_nickname': instance.consumerNickname,
      'provider_id': instance.providerId,
      'provider_nickname': instance.providerNickname,
      'quantity': instance.quantity,
      'unit_cost_points': instance.unitCostPoints,
      'total_cost_points': instance.totalCostPoints,
      'status': _$RedemptionOrderStatusEnumMap[instance.status]!,
      'auto_fulfill': instance.autoFulfill,
      'auto_complete': instance.autoComplete,
      'provider_incentive_ratio': instance.providerIncentiveRatio,
      'unsatisfied_reason': instance.unsatisfiedReason,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'fulfilled_at': instance.fulfilledAt?.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
    };

const _$RedemptionOrderStatusEnumMap = {
  RedemptionOrderStatus.awaitingFulfill: 'awaiting_fulfill',
  RedemptionOrderStatus.awaitingConfirm: 'awaiting_confirm',
  RedemptionOrderStatus.completed: 'completed',
  RedemptionOrderStatus.unsatisfied: 'unsatisfied',
};
