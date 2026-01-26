part of 'agreement_form_bloc.dart';

sealed class AgreementFormEvent {
  const AgreementFormEvent();
}

final class InitializeForm extends AgreementFormEvent {
  const InitializeForm({required this.groupId, this.agreement});

  final int groupId;
  final Agreement? agreement; // null for create, non-null for edit
}

final class NameChanged extends AgreementFormEvent {
  const NameChanged(this.name);

  final String name;
}

final class DescriptionChanged extends AgreementFormEvent {
  const DescriptionChanged(this.description);

  final String description;
}

final class PointsChanged extends AgreementFormEvent {
  const PointsChanged(this.points);

  final int points;
}

final class RequireConfirmationChanged extends AgreementFormEvent {
  const RequireConfirmationChanged(this.requireConfirmation);

  final bool requireConfirmation;
}

final class CoverImageUrlChanged extends AgreementFormEvent {
  const CoverImageUrlChanged(this.coverImageUrl);

  final String coverImageUrl;
}

final class ApplicableMembersChanged extends AgreementFormEvent {
  const ApplicableMembersChanged(this.memberIds);

  final List<int> memberIds;
}

final class SubmitAgreement extends AgreementFormEvent {
  const SubmitAgreement({
    required this.groupId,
    this.agreementId, // null for create, non-null for edit
  });

  final int groupId;
  final int? agreementId;
}
