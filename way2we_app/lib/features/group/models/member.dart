import 'package:equatable/equatable.dart';

enum GroupRole {
  admin,
  member;

  static GroupRole fromString(String value) {
    return GroupRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => GroupRole.member,
    );
  }
}

class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: GroupRole.fromString(json['role'] as String),
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  final int id;
  final int userId;
  final String nickname;
  final String? avatarUrl;
  final GroupRole role;
  final List<String> permissions;
  final DateTime joinedAt;

  bool hasPermission(String permission) {
    return role == GroupRole.admin || permissions.contains(permission);
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    nickname,
    avatarUrl,
    role,
    permissions,
    joinedAt,
  ];

  GroupMember copyWith({
    int? id,
    int? userId,
    String? nickname,
    String? avatarUrl,
    GroupRole? role,
    List<String>? permissions,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
