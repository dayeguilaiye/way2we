part of 'agreement_completion_record_bloc.dart';

sealed class AgreementCompletionRecordState extends Equatable {
  const AgreementCompletionRecordState();

  @override
  List<Object?> get props => [];
}

class AgreementCompletionRecordInitial extends AgreementCompletionRecordState {
  const AgreementCompletionRecordInitial();
}

class AgreementCompletionRecordSubmitting extends AgreementCompletionRecordState {
  const AgreementCompletionRecordSubmitting();
}

class AgreementCompletionRecordSuccess extends AgreementCompletionRecordState {
  const AgreementCompletionRecordSuccess(this.completion);

  final AgreementCompletion completion;

  @override
  List<Object?> get props => [completion];
}

class AgreementCompletionRecordFailure extends AgreementCompletionRecordState {
  const AgreementCompletionRecordFailure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
