part of 'group_members_bloc.dart';

sealed class GroupMembersState extends Equatable {
  const GroupMembersState();

  @override
  List<Object?> get props => [];
}

class GroupMembersInitial extends GroupMembersState {}

class GroupMembersLoading extends GroupMembersState {}

class GroupMembersLoaded extends GroupMembersState {
  const GroupMembersLoaded(this.members);
  final List<GroupMember> members;

  @override
  List<Object?> get props => [members];
}

class GroupMembersError extends GroupMembersState {
  const GroupMembersError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class MemberOperationInProgress extends GroupMembersState {}

class MemberOperationSuccess extends GroupMembersState {
  const MemberOperationSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class MemberOperationFailure extends GroupMembersState {
  const MemberOperationFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
