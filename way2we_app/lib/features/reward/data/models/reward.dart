import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reward.g.dart';

/// Reward status enum
enum RewardStatus { active, inactive }

/// Reward model representing a reward item
@JsonSerializable()
class Reward extends Equatable {
  const Reward({
    required this.id,
    required this.name,
    required this.costPoints,
    required this.status,
    required this.autoFulfill,
    required this.autoComplete,
    required this.groupId,
    required this.providerId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverImageUrl,
    this.providerNickname,
    this.isPinned = false,
  });

  /// Creates a [Reward] from JSON.
  factory Reward.fromJson(Map<String, dynamic> json) => _$RewardFromJson(json);

  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'cost_points')
  final int costPoints;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(unknownEnumValue: RewardStatus.active)
  final RewardStatus status;
  @JsonKey(name: 'auto_fulfill')
  final bool autoFulfill;
  @JsonKey(name: 'auto_complete')
  final bool autoComplete;
  @JsonKey(name: 'group_id')
  final int groupId;
  @JsonKey(name: 'provider_id')
  final int providerId;
  @JsonKey(name: 'provider_nickname')
  final String? providerNickname;
  @JsonKey(name: 'is_pinned', defaultValue: false)
  final bool isPinned;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$RewardToJson(this);

  bool get isActive => status == RewardStatus.active;

  Reward copyWith({bool? isPinned}) {
    return Reward(
      id: id,
      name: name,
      description: description,
      costPoints: costPoints,
      coverImageUrl: coverImageUrl,
      status: status,
      autoFulfill: autoFulfill,
      autoComplete: autoComplete,
      groupId: groupId,
      providerId: providerId,
      providerNickname: providerNickname,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    costPoints,
    coverImageUrl,
    status,
    autoFulfill,
    autoComplete,
    groupId,
    providerId,
    providerNickname,
    isPinned,
    createdAt,
    updatedAt,
  ];
}
