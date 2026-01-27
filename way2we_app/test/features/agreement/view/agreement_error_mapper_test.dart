import 'package:flutter_test/flutter_test.dart';
import 'package:way2we_app/features/agreement/view/agreement_error_mapper.dart';

void main() {
  test('agreementErrorTypeForCode maps pin/unpin codes', () {
    expect(
      agreementErrorTypeForCode('ERR_PIN_AGREEMENT_NOT_MEMBER'),
      AgreementErrorType.notMember,
    );
    expect(
      agreementErrorTypeForCode('ERR_UNPIN_AGREEMENT_NOT_FOUND'),
      AgreementErrorType.notFound,
    );
    expect(
      agreementErrorTypeForCode('ERR_PIN_AGREEMENT_FAILED'),
      AgreementErrorType.pinFailed,
    );
    expect(
      agreementErrorTypeForCode('ERR_UNPIN_AGREEMENT_FAILED'),
      AgreementErrorType.unpinFailed,
    );
  });

  test('agreementErrorTypeForCode maps generic codes', () {
    expect(
      agreementErrorTypeForCode('ERR_LIST_AGREEMENTS_FAILED'),
      AgreementErrorType.loadFailed,
    );
    expect(
      agreementErrorTypeForCode('ERR_UPDATE_STATUS_FAILED'),
      AgreementErrorType.updateFailed,
    );
    expect(agreementErrorTypeForCode('UNKNOWN'), AgreementErrorType.generic);
    expect(agreementErrorTypeForCode(null), AgreementErrorType.generic);
  });
}
