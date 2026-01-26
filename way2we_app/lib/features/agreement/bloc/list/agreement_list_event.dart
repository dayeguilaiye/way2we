part of 'agreement_list_bloc.dart';

sealed class AgreementListEvent {
  const AgreementListEvent();
}

final class LoadAgreements extends AgreementListEvent {
  const LoadAgreements({required this.groupId, this.statusFilter});

  final int groupId;
  final String? statusFilter;
}

final class RefreshAgreements extends AgreementListEvent {
  const RefreshAgreements();
}
