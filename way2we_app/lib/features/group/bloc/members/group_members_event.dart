part of 'group_members_bloc.dart';

sealed class GroupMembersEvent extends Equatable {
  const GroupMembersEvent();

  @override
  List<Object> get props => [];
}

class LoadGroupMembers extends GroupMembersEvent {
  const LoadGroupMembers(this.groupId);
  final int groupId;

  @override
  List<Object> get props => [groupId];
}

class UpdateMemberRole extends GroupMembersEvent {
  const UpdateMemberRole({
    required this.groupId,
    required this.userId,
    required this.role,
  });

  final int groupId;
  final int userId;
  final GroupRole role;

  @override
  List<Object> get props => [groupId, userId, role];
}

class UpdateMemberPermissions extends GroupMembersEvent {
  const UpdateMemberPermissions({
    required this.groupId,
    required this.userId,
    required this.permissions,
  });

  final int groupId;
  final int userId;
  final List<String> permissions;

  @override
  List<Object> get props => [groupId, userId, permissions];
}
