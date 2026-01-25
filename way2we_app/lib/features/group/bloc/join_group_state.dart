part of 'join_group_bloc.dart';

enum JoinGroupStatus {
  initial,
  loadingPreview,
  previewLoaded,
  joining,
  success,
  failure,
}

class JoinGroupState {
  const JoinGroupState({
    this.status = JoinGroupStatus.initial,
    this.invitationCode = '',
    this.groupId,
    this.groupName,
    this.memberCount,
    this.errorMessage,
    this.errorCode,
  });

  final JoinGroupStatus status;
  final String invitationCode;
  final int? groupId;
  final String? groupName;
  final int? memberCount;
  final String? errorMessage;
  final String? errorCode;

  /// Code is valid if it's 6 alphanumeric characters.
  bool get isCodeValid {
    if (invitationCode.length != 6) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(invitationCode);
  }

  /// Has preview data ready.
  bool get hasPreview => groupId != null && groupName != null;

  bool get isLoading =>
      status == JoinGroupStatus.loadingPreview ||
      status == JoinGroupStatus.joining;

  bool get canPreview =>
      isCodeValid && status != JoinGroupStatus.loadingPreview;

  bool get canJoin => hasPreview && !isLoading;

  JoinGroupState copyWith({
    JoinGroupStatus? status,
    String? invitationCode,
    int? groupId,
    String? groupName,
    int? memberCount,
    String? errorMessage,
    String? errorCode,
  }) {
    return JoinGroupState(
      status: status ?? this.status,
      invitationCode: invitationCode ?? this.invitationCode,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      memberCount: memberCount ?? this.memberCount,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}
