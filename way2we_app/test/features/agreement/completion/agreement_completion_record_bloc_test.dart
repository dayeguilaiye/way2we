import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/completion/bloc/record/agreement_completion_record_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';

class MockCompletionProvider extends Mock
    implements AgreementCompletionProvider {}

void main() {
  late AgreementCompletionProvider provider;
  late AgreementCompletionRecordBloc bloc;

  setUp(() {
    provider = MockCompletionProvider();
    bloc = AgreementCompletionRecordBloc(completionProvider: provider);
  });

  AgreementCompletion buildCompletion() {
    return AgreementCompletion(
      id: 1,
      groupId: 10,
      agreementId: 5,
      completerId: 2,
      recorderId: 3,
      points: 5,
      requireConfirmation: true,
      status: AgreementCompletionStatus.pending,
      createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    );
  }

  test('initial state is AgreementCompletionRecordInitial', () {
    expect(bloc.state, equals(const AgreementCompletionRecordInitial()));
  });

  blocTest<AgreementCompletionRecordBloc, AgreementCompletionRecordState>(
    'emits submitting then success on submit',
    build: () {
      when(
        () => provider.createAgreementCompletion(
          groupId: 10,
          agreementId: 5,
          completerId: 2,
        ),
      ).thenAnswer((_) async => buildCompletion());
      return bloc;
    },
    act: (bloc) => bloc.add(
      const SubmitAgreementCompletion(
        groupId: 10,
        agreementId: 5,
        completerId: 2,
      ),
    ),
    expect: () => [
      const AgreementCompletionRecordSubmitting(),
      AgreementCompletionRecordSuccess(buildCompletion()),
    ],
  );

  blocTest<AgreementCompletionRecordBloc, AgreementCompletionRecordState>(
    'emits failure on submit error',
    build: () {
      when(
        () => provider.createAgreementCompletion(
          groupId: 10,
          agreementId: 5,
          completerId: 2,
        ),
      ).thenThrow(
        const AgreementCompletionApiException(
          'Submit failed',
          code: 'ERR_SUBMIT',
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(
      const SubmitAgreementCompletion(
        groupId: 10,
        agreementId: 5,
        completerId: 2,
      ),
    ),
    expect: () => [
      const AgreementCompletionRecordSubmitting(),
      const AgreementCompletionRecordFailure(
        message: 'Submit failed',
        code: 'ERR_SUBMIT',
      ),
    ],
  );
}
