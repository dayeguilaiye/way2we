part of 'agreement_completion_record_bloc.dart';

sealed class AgreementCompletionRecordEvent extends Equatable {
  const AgreementCompletionRecordEvent();

  @override
  List<Object?> get props => [];
}

class SubmitAgreementCompletion extends AgreementCompletionRecordEvent {
  const SubmitAgreementCompletion({
    required this.groupId,
    required this.agreementId,
    this.completerId,
  });

  final int groupId;
  final int agreementId;
  final int? completerId;

  @override
  List<Object?> get props => [groupId, agreementId, completerId];
}

class ResetAgreementCompletionStatus extends AgreementCompletionRecordEvent {
  const ResetAgreementCompletionStatus();
}
