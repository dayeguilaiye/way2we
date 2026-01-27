import 'package:flutter/widgets.dart';
import 'package:way2we_app/l10n/l10n.dart';

enum AgreementErrorType {
  notMember,
  notFound,
  pinFailed,
  unpinFailed,
  loadFailed,
  updateFailed,
  generic,
}

AgreementErrorType agreementErrorTypeForCode(String? code) {
  switch (code) {
    case 'ERR_NOT_MEMBER':
    case 'ERR_PIN_AGREEMENT_NOT_MEMBER':
    case 'ERR_UNPIN_AGREEMENT_NOT_MEMBER':
      return AgreementErrorType.notMember;
    case 'ERR_AGREEMENT_NOT_FOUND':
    case 'ERR_PIN_AGREEMENT_NOT_FOUND':
    case 'ERR_UNPIN_AGREEMENT_NOT_FOUND':
      return AgreementErrorType.notFound;
    case 'ERR_PIN_AGREEMENT_FAILED':
      return AgreementErrorType.pinFailed;
    case 'ERR_UNPIN_AGREEMENT_FAILED':
      return AgreementErrorType.unpinFailed;
    case 'ERR_LIST_AGREEMENTS_FAILED':
    case 'ERR_GET_AGREEMENT_FAILED':
      return AgreementErrorType.loadFailed;
    case 'ERR_UPDATE_STATUS_FAILED':
    case 'ERR_UPDATE_AGREEMENT_FAILED':
      return AgreementErrorType.updateFailed;
    default:
      return AgreementErrorType.generic;
  }
}

String agreementErrorMessage(BuildContext context, String? code) {
  final l10n = context.l10n;
  switch (agreementErrorTypeForCode(code)) {
    case AgreementErrorType.notMember:
      return l10n.agreementNotMemberError;
    case AgreementErrorType.notFound:
      return l10n.agreementNotFoundError;
    case AgreementErrorType.pinFailed:
      return l10n.agreementPinError;
    case AgreementErrorType.unpinFailed:
      return l10n.agreementUnpinError;
    case AgreementErrorType.loadFailed:
      return l10n.agreementLoadError;
    case AgreementErrorType.updateFailed:
      return l10n.agreementUpdateError;
    case AgreementErrorType.generic:
      return l10n.agreementGenericError;
  }
}
