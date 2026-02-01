import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';

part 'agreement_completion_record_event.dart';
part 'agreement_completion_record_state.dart';

class AgreementCompletionRecordBloc
    extends Bloc<AgreementCompletionRecordEvent, AgreementCompletionRecordState> {
  AgreementCompletionRecordBloc({
    required AgreementCompletionProvider completionProvider,
  })  : _completionProvider = completionProvider,
        super(const AgreementCompletionRecordInitial()) {
    on<SubmitAgreementCompletion>(_onSubmit);
    on<ResetAgreementCompletionStatus>(_onReset);
  }

  final AgreementCompletionProvider _completionProvider;

  Future<void> _onSubmit(
    SubmitAgreementCompletion event,
    Emitter<AgreementCompletionRecordState> emit,
  ) async {
    emit(const AgreementCompletionRecordSubmitting());

    try {
      final completion = await _completionProvider.createAgreementCompletion(
        groupId: event.groupId,
        agreementId: event.agreementId,
        completerId: event.completerId,
      );

      emit(AgreementCompletionRecordSuccess(completion));
    } on AgreementCompletionApiException catch (e) {
      emit(
        AgreementCompletionRecordFailure(message: e.message, code: e.code),
      );
    } on Exception catch (e) {
      emit(AgreementCompletionRecordFailure(message: e.toString()));
    }
  }

  void _onReset(
    ResetAgreementCompletionStatus event,
    Emitter<AgreementCompletionRecordState> emit,
  ) {
    emit(const AgreementCompletionRecordInitial());
  }
}
