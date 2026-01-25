part of 'group_control_bloc.dart';

sealed class GroupControlState extends Equatable {
  const GroupControlState();

  @override
  List<Object?> get props => [];
}

final class GroupControlInitial extends GroupControlState {}

final class GroupControlLoadInProgress extends GroupControlState {}

final class GroupControlLoadSuccess extends GroupControlState {
  const GroupControlLoadSuccess({
    required this.groups,
    this.selectedGroup,
  });

  final List<UserGroup> groups;
  final UserGroup? selectedGroup;

  @override
  List<Object?> get props => [groups, selectedGroup];

  GroupControlLoadSuccess copyWith({
    List<UserGroup>? groups,
    UserGroup? selectedGroup,
  }) {
    return GroupControlLoadSuccess(
      groups: groups ?? this.groups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}

final class GroupControlLoadFailure extends GroupControlState {
  const GroupControlLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
