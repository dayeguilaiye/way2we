part of 'create_group_bloc.dart';

enum CreateGroupStatus {
  initial,
  submitting,
  success,
  failure,
}

class CreateGroupState {
  const CreateGroupState({
    this.status = CreateGroupStatus.initial,
    this.name = '',
    this.groupId,
    this.errorMessage,
  });

  final CreateGroupStatus status;
  final String name;
  final int? groupId;
  final String? errorMessage;

  /// Name is valid if it's between 1 and 30 characters.
  bool get isNameValid => name.isNotEmpty && name.length <= 30;

  /// Can submit if name is valid and not currently submitting.
  bool get canSubmit => isNameValid && status != CreateGroupStatus.submitting;

  CreateGroupState copyWith({
    CreateGroupStatus? status,
    String? name,
    int? groupId,
    String? errorMessage,
  }) {
    return CreateGroupState(
      status: status ?? this.status,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      errorMessage: errorMessage,
    );
  }
}
