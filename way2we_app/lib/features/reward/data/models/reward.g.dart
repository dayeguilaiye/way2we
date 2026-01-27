// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reward _$RewardFromJson(Map<String, dynamic> json) => Reward(
  id: json['id'] as int,
  name: json['name'] as String,
  description: json['description'] as String?,
  costPoints: json['cost_points'] as int,
  coverImageUrl: json['cover_image_url'] as String?,
  status:
      $enumDecodeNullable(_$RewardStatusEnumMap, json['status']) ??
      RewardStatus.active,
  autoFulfill: json['auto_fulfill'] as bool,
  autoComplete: json['auto_complete'] as bool,
  groupId: json['group_id'] as int,
  providerId: json['provider_id'] as int,
  providerNickname: json['provider_nickname'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RewardToJson(Reward instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'cost_points': instance.costPoints,
  'cover_image_url': instance.coverImageUrl,
  'status': _$RewardStatusEnumMap[instance.status],
  'auto_fulfill': instance.autoFulfill,
  'auto_complete': instance.autoComplete,
  'group_id': instance.groupId,
  'provider_id': instance.providerId,
  'provider_nickname': instance.providerNickname,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$RewardStatusEnumMap = {
  RewardStatus.active: 'active',
  RewardStatus.inactive: 'inactive',
};
