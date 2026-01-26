import 'package:equatable/equatable.dart';

/// Agreement status enum
enum AgreementStatus {
  active,
  inactive;

  static AgreementStatus fromString(String value) {
    return AgreementStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AgreementStatus.active,
    );
  }
}

/// Agreement model representing a group agreement/task rule
class Agreement extends Equatable {
  const Agreement({
    required this.id,
    required this.name,
    required this.points,
    required this.requireConfirmation,
    required this.status,
    required this.groupId,
    required this.creatorId,
    required this.applicableMemberIds,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverImageUrl,
  });

  factory Agreement.fromJson(Map<String, dynamic> json) {
    return Agreement(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      points: json['points'] as int,
      requireConfirmation: json['require_confirmation'] as bool,
      coverImageUrl: json['cover_image_url'] as String?,
      status: AgreementStatus.fromString(json['status'] as String),
      groupId: json['group_id'] as int,
      creatorId: json['creator_id'] as int,
      applicableMemberIds:
          (json['applicable_member_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final int id;
  final String name;
  final String? description;
  final int points;
  final bool requireConfirmation;
  final String? coverImageUrl;
  final AgreementStatus status;
  final int groupId;
  final int creatorId;
  final List<int> applicableMemberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'require_confirmation': requireConfirmation,
      'cover_image_url': coverImageUrl,
      'status': status.name,
      'group_id': groupId,
      'creator_id': creatorId,
      'applicable_member_ids': applicableMemberIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == AgreementStatus.active;

  bool get appliesToAllMembers => applicableMemberIds.isEmpty;

  Agreement copyWith({
    int? id,
    String? name,
    String? description,
    int? points,
    bool? requireConfirmation,
    String? coverImageUrl,
    AgreementStatus? status,
    int? groupId,
    int? creatorId,
    List<int>? applicableMemberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agreement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      applicableMemberIds: applicableMemberIds ?? this.applicableMemberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    points,
    requireConfirmation,
    coverImageUrl,
    status,
    groupId,
    creatorId,
    applicableMemberIds,
    createdAt,
    updatedAt,
  ];
}
