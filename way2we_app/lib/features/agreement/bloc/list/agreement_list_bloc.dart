import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';

part 'agreement_list_event.dart';
part 'agreement_list_state.dart';

class AgreementListBloc extends Bloc<AgreementListEvent, AgreementListState> {
  AgreementListBloc({required AgreementProvider agreementProvider})
    : _agreementProvider = agreementProvider,
      super(const AgreementListInitial()) {
    on<LoadAgreements>(_onLoadAgreements);
    on<RefreshAgreements>(_onRefreshAgreements);
    on<TogglePinAgreement>(_onTogglePinAgreement);
  }

  final AgreementProvider _agreementProvider;
  int? _currentGroupId;
  String? _currentStatusFilter;

  Future<void> _onLoadAgreements(
    LoadAgreements event,
    Emitter<AgreementListState> emit,
  ) async {
    _currentGroupId = event.groupId;
    _currentStatusFilter = event.statusFilter;

    emit(const AgreementListLoading());

    try {
      final agreements = await _agreementProvider.listAgreements(
        groupId: event.groupId,
        status: event.statusFilter,
      );

      emit(
        AgreementListLoaded(
          agreements: agreements,
          groupId: event.groupId,
          statusFilter: event.statusFilter,
        ),
      );
    } on AgreementApiException catch (e) {
      emit(AgreementListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(AgreementListError(message: e.toString()));
    }
  }

  Future<void> _onRefreshAgreements(
    RefreshAgreements event,
    Emitter<AgreementListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    // Keep current state while refreshing (don't show loading indicator)
    try {
      final agreements = await _agreementProvider.listAgreements(
        groupId: _currentGroupId!,
        status: _currentStatusFilter,
      );

      emit(
        AgreementListLoaded(
          agreements: agreements,
          groupId: _currentGroupId!,
          statusFilter: _currentStatusFilter,
        ),
      );
    } on AgreementApiException catch (e) {
      emit(AgreementListError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(AgreementListError(message: e.toString()));
    }
  }

  Future<void> _onTogglePinAgreement(
    TogglePinAgreement event,
    Emitter<AgreementListState> emit,
  ) async {
    if (_currentGroupId == null) return;

    final currentState = state;
    if (currentState is! AgreementListReadyState) return;

    final previousAgreements = currentState.agreements;
    final updatedAgreements = previousAgreements
        .map(
          (agreement) => agreement.id == event.agreementId
              ? agreement.copyWith(isPinned: !event.currentPinStatus)
              : agreement,
        )
        .toList();

    emit(
      AgreementListLoaded(
        agreements: updatedAgreements,
        groupId: currentState.groupId,
        statusFilter: currentState.statusFilter,
      ),
    );

    try {
      if (event.currentPinStatus) {
        await _agreementProvider.unpinAgreement(
          groupId: _currentGroupId!,
          agreementId: event.agreementId,
        );
      } else {
        await _agreementProvider.pinAgreement(
          groupId: _currentGroupId!,
          agreementId: event.agreementId,
        );
      }

      emit(
        AgreementListActionSuccess(
          agreements: updatedAgreements,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          isPinned: !event.currentPinStatus,
        ),
      );
    } on AgreementApiException catch (e) {
      emit(
        AgreementListActionFailure(
          agreements: previousAgreements,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.message,
          code: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        AgreementListActionFailure(
          agreements: previousAgreements,
          groupId: currentState.groupId,
          statusFilter: currentState.statusFilter,
          message: e.toString(),
        ),
      );
    }
  }
}
