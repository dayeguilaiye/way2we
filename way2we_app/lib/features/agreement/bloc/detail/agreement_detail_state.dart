part of 'agreement_detail_bloc.dart';

sealed class AgreementDetailState {
  const AgreementDetailState();
}

final class AgreementDetailInitial extends AgreementDetailState {
  const AgreementDetailInitial();
}

final class AgreementDetailLoading extends AgreementDetailState {
  const AgreementDetailLoading();
}

final class AgreementDetailLoaded extends AgreementDetailState {
  const AgreementDetailLoaded({
    required this.agreement,
    required this.groupId,
  });

  final Agreement agreement;
  final int groupId;
}

final class AgreementStatusUpdating extends AgreementDetailState {
  const AgreementStatusUpdating({required this.agreement});

  final Agreement agreement;
}

final class AgreementStatusUpdateSuccess extends AgreementDetailState {
  const AgreementStatusUpdateSuccess({required this.agreement});

  final Agreement agreement;
}

final class AgreementDetailError extends AgreementDetailState {
  const AgreementDetailError({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;
}
