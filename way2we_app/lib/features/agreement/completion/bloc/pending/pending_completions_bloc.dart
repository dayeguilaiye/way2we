import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/completion/data/providers/agreement_completion_provider.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';

part 'pending_completions_event.dart';
part 'pending_completions_state.dart';

class PendingCompletionsBloc
    extends Bloc<PendingCompletionsEvent, PendingCompletionsState> {
  PendingCompletionsBloc({
    required AgreementCompletionProvider completionProvider,
  })  : _completionProvider = completionProvider,
        super(const PendingCompletionsInitial()) {
    on<LoadPendingCompletions>(_onLoad);
    on<RefreshPendingCompletions>(_onRefresh);
    on<ConfirmPendingCompletion>(_onConfirm);
    on<RejectPendingCompletion>(_onReject);
  }

  final AgreementCompletionProvider _completionProvider;
  int? _groupId;
  int? _limit;
  int? _offset;

  Future<void> _onLoad(
    LoadPendingCompletions event,
    Emitter<PendingCompletionsState> emit,
  ) async {
    _groupId = event.groupId;
    _limit = event.limit;
    _offset = event.offset;

    emit(const PendingCompletionsLoading());

    try {
      final completions = await _completionProvider.listPendingCompletions(
        groupId: event.groupId,
        limit: event.limit,
        offset: event.offset,
      );
      emit(
        PendingCompletionsLoaded(
          completions: completions,
          groupId: event.groupId,
        ),
      );
    } on AgreementCompletionApiException catch (e) {
      emit(PendingCompletionsError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(PendingCompletionsError(message: e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshPendingCompletions event,
    Emitter<PendingCompletionsState> emit,
  ) async {
    if (_groupId == null) return;

    try {
      final completions = await _completionProvider.listPendingCompletions(
        groupId: _groupId!,
        limit: _limit,
        offset: _offset,
      );
      emit(
        PendingCompletionsLoaded(
          completions: completions,
          groupId: _groupId!,
        ),
      );
    } on AgreementCompletionApiException catch (e) {
      emit(PendingCompletionsError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(PendingCompletionsError(message: e.toString()));
    }
  }

  Future<void> _onConfirm(
    ConfirmPendingCompletion event,
    Emitter<PendingCompletionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PendingCompletionsReadyState) return;

    final previous = currentState.completions;
    final updated = previous
        .where((completion) => completion.id != event.completionId)
        .toList();

    emit(
      PendingCompletionsLoaded(
        completions: updated,
        groupId: currentState.groupId,
      ),
    );

    try {
      await _completionProvider.confirmCompletion(
        groupId: currentState.groupId,
        completionId: event.completionId,
      );

      emit(
        PendingCompletionsActionSuccess(
          completions: updated,
          groupId: currentState.groupId,
          action: PendingCompletionAction.confirm,
        ),
      );
    } on AgreementCompletionApiException catch (e) {
      emit(
        PendingCompletionsActionFailure(
          completions: previous,
          groupId: currentState.groupId,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        PendingCompletionsActionFailure(
          completions: previous,
          groupId: currentState.groupId,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onReject(
    RejectPendingCompletion event,
    Emitter<PendingCompletionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PendingCompletionsReadyState) return;

    final previous = currentState.completions;
    final updated = previous
        .where((completion) => completion.id != event.completionId)
        .toList();

    emit(
      PendingCompletionsLoaded(
        completions: updated,
        groupId: currentState.groupId,
      ),
    );

    try {
      await _completionProvider.rejectCompletion(
        groupId: currentState.groupId,
        completionId: event.completionId,
        reason: event.reason,
      );

      emit(
        PendingCompletionsActionSuccess(
          completions: updated,
          groupId: currentState.groupId,
          action: PendingCompletionAction.reject,
        ),
      );
    } on AgreementCompletionApiException catch (e) {
      emit(
        PendingCompletionsActionFailure(
          completions: previous,
          groupId: currentState.groupId,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        PendingCompletionsActionFailure(
          completions: previous,
          groupId: currentState.groupId,
          message: e.toString(),
        ),
      );
    }
  }
}
