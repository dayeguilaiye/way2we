part of 'pending_completions_bloc.dart';

sealed class PendingCompletionsEvent extends Equatable {
  const PendingCompletionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingCompletions extends PendingCompletionsEvent {
  const LoadPendingCompletions({
    required this.groupId,
    this.limit,
    this.offset,
  });

  final int groupId;
  final int? limit;
  final int? offset;

  @override
  List<Object?> get props => [groupId, limit, offset];
}

class RefreshPendingCompletions extends PendingCompletionsEvent {
  const RefreshPendingCompletions();
}

class ConfirmPendingCompletion extends PendingCompletionsEvent {
  const ConfirmPendingCompletion({required this.completionId});

  final int completionId;

  @override
  List<Object?> get props => [completionId];
}

class RejectPendingCompletion extends PendingCompletionsEvent {
  const RejectPendingCompletion({required this.completionId, this.reason});

  final int completionId;
  final String? reason;

  @override
  List<Object?> get props => [completionId, reason];
}
