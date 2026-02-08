import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2we_app/features/agreement/completion/bloc/pending/pending_completions_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';

class MockCompletionProvider extends Mock
    implements AgreementCompletionProvider {}

void main() {
  late AgreementCompletionProvider provider;
  late PendingCompletionsBloc bloc;

  setUp(() {
    provider = MockCompletionProvider();
    bloc = PendingCompletionsBloc(completionProvider: provider);
  });

  AgreementCompletion buildCompletion(int id) {
    return AgreementCompletion(
      id: id,
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

  blocTest<PendingCompletionsBloc, PendingCompletionsState>(
    'emits loaded when load succeeds',
    build: () {
      when(
        () => provider.listPendingCompletions(
          groupId: 10,
        ),
      ).thenAnswer((_) async => [buildCompletion(1)]);
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadPendingCompletions(groupId: 10)),
    expect: () => [
      const PendingCompletionsLoading(),
      PendingCompletionsLoaded(completions: [buildCompletion(1)], groupId: 10),
    ],
  );

  blocTest<PendingCompletionsBloc, PendingCompletionsState>(
    'emits action success when confirm succeeds',
    build: () {
      final completions = [buildCompletion(1), buildCompletion(2)];
      when(
        () => provider.listPendingCompletions(
          groupId: 10,
        ),
      ).thenAnswer((_) async => completions);
      when(
        () => provider.confirmCompletion(groupId: 10, completionId: 1),
      ).thenAnswer((_) async {});
      return bloc;
    },
    act: (bloc) => bloc
      ..add(const LoadPendingCompletions(groupId: 10))
      ..add(const ConfirmPendingCompletion(completionId: 1)),
    expect: () => [
      const PendingCompletionsLoading(),
      PendingCompletionsLoaded(
        completions: [buildCompletion(1), buildCompletion(2)],
        groupId: 10,
      ),
      PendingCompletionsLoaded(
        completions: [buildCompletion(2)],
        groupId: 10,
      ),
      PendingCompletionsActionSuccess(
        completions: [buildCompletion(2)],
        groupId: 10,
        action: PendingCompletionAction.confirm,
      ),
    ],
  );

  blocTest<PendingCompletionsBloc, PendingCompletionsState>(
    'emits action failure when reject fails',
    build: () {
      final completions = [buildCompletion(1), buildCompletion(2)];
      when(
        () => provider.listPendingCompletions(
          groupId: 10,
        ),
      ).thenAnswer((_) async => completions);
      when(
        () => provider.rejectCompletion(
          groupId: 10,
          completionId: 1,
          reason: 'no',
        ),
      ).thenThrow(
        const AgreementCompletionApiException(
          'Reject failed',
          code: 'ERR_REJECT',
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc
      ..add(const LoadPendingCompletions(groupId: 10))
      ..add(const RejectPendingCompletion(completionId: 1, reason: 'no')),
    expect: () => [
      const PendingCompletionsLoading(),
      PendingCompletionsLoaded(
        completions: [buildCompletion(1), buildCompletion(2)],
        groupId: 10,
      ),
      PendingCompletionsLoaded(
        completions: [buildCompletion(2)],
        groupId: 10,
      ),
      PendingCompletionsActionFailure(
        completions: [buildCompletion(1), buildCompletion(2)],
        groupId: 10,
        message: 'Reject failed',
        code: 'ERR_REJECT',
      ),
    ],
  );
}
