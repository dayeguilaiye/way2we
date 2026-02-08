part of 'agreement_list_bloc.dart';

sealed class AgreementListState extends Equatable {
  const AgreementListState();

  @override
  List<Object?> get props => [];
}

final class AgreementListInitial extends AgreementListState {
  const AgreementListInitial();
}

final class AgreementListLoading extends AgreementListState {
  const AgreementListLoading();
}

sealed class AgreementListReadyState extends AgreementListState {
  const AgreementListReadyState({
    required this.agreements,
    required this.groupId,
    this.statusFilter,
  });

  final List<Agreement> agreements;
  final int groupId;
  final String? statusFilter;

  List<Agreement> get activeAgreements =>
      agreements.where((a) => a.isActive).toList();

  List<Agreement> get inactiveAgreements =>
      agreements.where((a) => !a.isActive).toList();

  bool get isEmpty => agreements.isEmpty;

  @override
  List<Object?> get props => [agreements, groupId, statusFilter];
}

final class AgreementListLoaded extends AgreementListReadyState {
  const AgreementListLoaded({
    required super.agreements,
    required super.groupId,
    super.statusFilter,
  });
}

final class AgreementListActionSuccess extends AgreementListReadyState {
  const AgreementListActionSuccess({
    required super.agreements,
    required super.groupId,
    required this.isPinned,
    super.statusFilter,
  });

  final bool isPinned;

  @override
  List<Object?> get props => [...super.props, isPinned];
}

final class AgreementListActionFailure extends AgreementListReadyState {
  const AgreementListActionFailure({
    required super.agreements,
    required super.groupId,
    required this.message,
    super.statusFilter,
    this.code,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => [...super.props, message, code];
}

final class AgreementListError extends AgreementListState {
  const AgreementListError({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
