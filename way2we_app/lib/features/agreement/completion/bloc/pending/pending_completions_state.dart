part of 'pending_completions_bloc.dart';

enum PendingCompletionAction { confirm, reject }

sealed class PendingCompletionsState extends Equatable {
  const PendingCompletionsState();

  @override
  List<Object?> get props => [];
}

class PendingCompletionsInitial extends PendingCompletionsState {
  const PendingCompletionsInitial();
}

class PendingCompletionsLoading extends PendingCompletionsState {
  const PendingCompletionsLoading();
}

class PendingCompletionsError extends PendingCompletionsState {
  const PendingCompletionsError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

sealed class PendingCompletionsReadyState extends PendingCompletionsState {
  const PendingCompletionsReadyState({
    required this.completions,
    required this.groupId,
  });

  final List<AgreementCompletion> completions;
  final int groupId;

  @override
  List<Object?> get props => [completions, groupId];
}

class PendingCompletionsLoaded extends PendingCompletionsReadyState {
  const PendingCompletionsLoaded({
    required super.completions,
    required super.groupId,
  });
}

class PendingCompletionsActionSuccess extends PendingCompletionsReadyState {
  const PendingCompletionsActionSuccess({
    required super.completions,
    required super.groupId,
    required this.action,
  });

  final PendingCompletionAction action;

  @override
  List<Object?> get props => [...super.props, action];
}

class PendingCompletionsActionFailure extends PendingCompletionsReadyState {
  const PendingCompletionsActionFailure({
    required super.completions,
    required super.groupId,
    required this.message,
    this.code,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => [...super.props, message, code];
}
