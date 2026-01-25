part of 'invitation_bloc.dart';

enum InvitationStatus {
  initial,
  loading,
  loaded,
  refreshing,
  refreshed,
  copied,
  failure,
}

class InvitationState {
  const InvitationState({
    this.status = InvitationStatus.initial,
    this.invitationCode = '',
    this.shareUrl = '',
    this.errorMessage,
    this.errorCode,
  });

  final InvitationStatus status;
  final String invitationCode;
  final String shareUrl;
  final String? errorMessage;
  final String? errorCode;

  /// Formatted invitation code with space for better readability.
  /// e.g., "ABC 123" instead of "ABC123"
  String get formattedCode {
    if (invitationCode.length != 6) return invitationCode;
    return '${invitationCode.substring(0, 3)} ${invitationCode.substring(3)}';
  }

  bool get isLoading =>
      status == InvitationStatus.loading ||
      status == InvitationStatus.refreshing;

  bool get hasCode => invitationCode.isNotEmpty;

  InvitationState copyWith({
    InvitationStatus? status,
    String? invitationCode,
    String? shareUrl,
    String? errorMessage,
    String? errorCode,
  }) {
    return InvitationState(
      status: status ?? this.status,
      invitationCode: invitationCode ?? this.invitationCode,
      shareUrl: shareUrl ?? this.shareUrl,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}
