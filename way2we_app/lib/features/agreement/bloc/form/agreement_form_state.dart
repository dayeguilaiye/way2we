part of 'agreement_form_bloc.dart';

enum AgreementFormStatus {
  initial,
  submitting,
  success,
  failure,
}

class AgreementFormState {
  const AgreementFormState({
    this.status = AgreementFormStatus.initial,
    this.name = '',
    this.description = '',
    this.points = 10,
    this.requireConfirmation = true,
    this.coverImageUrl = '',
    this.applicableMemberIds = const [],
    this.isEditMode = false,
    this.createdAgreement,
    this.errorMessage,
    this.errorCode,
  });

  final AgreementFormStatus status;
  final String name;
  final String description;
  final int points;
  final bool requireConfirmation;
  final String coverImageUrl;
  final List<int> applicableMemberIds;
  final bool isEditMode;
  final Agreement? createdAgreement;
  final String? errorMessage;
  final String? errorCode;

  // Validation getters
  bool get isNameValid => name.isNotEmpty && name.length <= 50;
  bool get isDescriptionValid => description.length <= 200;
  bool get isPointsValid => points >= 1 && points <= 99999;
  bool get isFormValid => isNameValid && isDescriptionValid && isPointsValid;
  bool get canSubmit => isFormValid && status != AgreementFormStatus.submitting;

  AgreementFormState copyWith({
    AgreementFormStatus? status,
    String? name,
    String? description,
    int? points,
    bool? requireConfirmation,
    String? coverImageUrl,
    List<int>? applicableMemberIds,
    bool? isEditMode,
    Agreement? createdAgreement,
    String? errorMessage,
    String? errorCode,
  }) {
    return AgreementFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      applicableMemberIds: applicableMemberIds ?? this.applicableMemberIds,
      isEditMode: isEditMode ?? this.isEditMode,
      createdAgreement: createdAgreement,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}
