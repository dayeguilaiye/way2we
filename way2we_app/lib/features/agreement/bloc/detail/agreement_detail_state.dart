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

final class AgreementPinUpdating extends AgreementDetailState {
  const AgreementPinUpdating({required this.agreement});

  final Agreement agreement;
}

final class AgreementPinUpdateSuccess extends AgreementDetailState {
  const AgreementPinUpdateSuccess({
    required this.agreement,
    required this.isPinned,
  });

  final Agreement agreement;
  final bool isPinned;
}

final class AgreementPinUpdateFailure extends AgreementDetailState {
  const AgreementPinUpdateFailure({
    required this.agreement,
    required this.message,
    this.code,
  });

  final Agreement agreement;
  final String message;
  final String? code;
}

final class AgreementDetailError extends AgreementDetailState {
  const AgreementDetailError({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;
}

extension AgreementDetailStateX on AgreementDetailState {
  Agreement? get agreementOrNull {
    if (this is AgreementDetailLoaded) {
      return (this as AgreementDetailLoaded).agreement;
    }
    if (this is AgreementStatusUpdating) {
      return (this as AgreementStatusUpdating).agreement;
    }
    if (this is AgreementStatusUpdateSuccess) {
      return (this as AgreementStatusUpdateSuccess).agreement;
    }
    if (this is AgreementPinUpdating) {
      return (this as AgreementPinUpdating).agreement;
    }
    if (this is AgreementPinUpdateSuccess) {
      return (this as AgreementPinUpdateSuccess).agreement;
    }
    if (this is AgreementPinUpdateFailure) {
      return (this as AgreementPinUpdateFailure).agreement;
    }
    return null;
  }
}
