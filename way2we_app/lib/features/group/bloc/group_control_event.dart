part of 'group_control_bloc.dart';

sealed class GroupControlEvent extends Equatable {
  const GroupControlEvent();

  @override
  List<Object?> get props => [];
}

final class GroupControlGroupsLoaded extends GroupControlEvent {
  const GroupControlGroupsLoaded();
}

final class GroupControlGroupSelected extends GroupControlEvent {
  const GroupControlGroupSelected(this.groupId);

  final int groupId;

  @override
  List<Object?> get props => [groupId];
}
