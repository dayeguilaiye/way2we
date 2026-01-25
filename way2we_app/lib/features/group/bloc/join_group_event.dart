part of 'join_group_bloc.dart';

abstract class JoinGroupEvent {
  const JoinGroupEvent();
}

/// Event when the invitation code input changes.
class JoinGroupCodeChanged extends JoinGroupEvent {
  const JoinGroupCodeChanged(this.code);

  final String code;
}

/// Event to preview the group before joining.
class JoinGroupPreviewRequested extends JoinGroupEvent {
  const JoinGroupPreviewRequested();
}

/// Event to confirm joining the group.
class JoinGroupConfirmed extends JoinGroupEvent {
  const JoinGroupConfirmed();
}
