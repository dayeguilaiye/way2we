part of 'create_group_bloc.dart';

abstract class CreateGroupEvent {
  const CreateGroupEvent();
}

/// Event to update the group name as user types.
class CreateGroupNameChanged extends CreateGroupEvent {
  const CreateGroupNameChanged(this.name);

  final String name;
}

/// Event to submit the create group request.
class CreateGroupSubmitted extends CreateGroupEvent {
  const CreateGroupSubmitted();
}
