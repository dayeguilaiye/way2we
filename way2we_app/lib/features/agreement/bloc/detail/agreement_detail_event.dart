part of 'agreement_detail_bloc.dart';

sealed class AgreementDetailEvent {
  const AgreementDetailEvent();
}

final class LoadAgreementDetail extends AgreementDetailEvent {
  const LoadAgreementDetail({
    required this.groupId,
    required this.agreementId,
  });

  final int groupId;
  final int agreementId;
}

final class UpdateAgreementStatus extends AgreementDetailEvent {
  const UpdateAgreementStatus({required this.newStatus});

  final String newStatus; // 'active' or 'inactive'
}

final class TogglePin extends AgreementDetailEvent {
  const TogglePin({required this.currentPinStatus});

  final bool currentPinStatus;
}
