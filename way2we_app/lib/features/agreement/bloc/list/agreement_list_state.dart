part of 'agreement_list_bloc.dart';

sealed class AgreementListState {
  const AgreementListState();
}

final class AgreementListInitial extends AgreementListState {
  const AgreementListInitial();
}

final class AgreementListLoading extends AgreementListState {
  const AgreementListLoading();
}

final class AgreementListLoaded extends AgreementListState {
  const AgreementListLoaded({
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
}

final class AgreementListError extends AgreementListState {
  const AgreementListError({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;
}
