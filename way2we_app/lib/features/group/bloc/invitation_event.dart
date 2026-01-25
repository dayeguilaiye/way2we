part of 'invitation_bloc.dart';

abstract class InvitationEvent {
  const InvitationEvent();
}

/// Event to load the invitation code.
class InvitationLoadRequested extends InvitationEvent {
  const InvitationLoadRequested();
}

/// Event to refresh the invitation code.
class InvitationRefreshRequested extends InvitationEvent {
  const InvitationRefreshRequested();
}

/// Event when invitation code is copied to clipboard.
class InvitationCopyRequested extends InvitationEvent {
  const InvitationCopyRequested();
}
