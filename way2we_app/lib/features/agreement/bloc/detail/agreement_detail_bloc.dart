import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/agreement/data/providers/agreement_provider.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';

part 'agreement_detail_event.dart';
part 'agreement_detail_state.dart';

class AgreementDetailBloc
    extends Bloc<AgreementDetailEvent, AgreementDetailState> {
  AgreementDetailBloc({required AgreementProvider agreementProvider})
      : _agreementProvider = agreementProvider,
        super(const AgreementDetailInitial()) {
    on<LoadAgreementDetail>(_onLoadAgreementDetail);
    on<UpdateAgreementStatus>(_onUpdateAgreementStatus);
    on<TogglePin>(_onTogglePin);
  }

  final AgreementProvider _agreementProvider;
  int? _currentGroupId;
  int? _currentAgreementId;

  Future<void> _onLoadAgreementDetail(
    LoadAgreementDetail event,
    Emitter<AgreementDetailState> emit,
  ) async {
    _currentGroupId = event.groupId;
    _currentAgreementId = event.agreementId;

    emit(const AgreementDetailLoading());

    try {
      final agreement = await _agreementProvider.getAgreement(
        groupId: event.groupId,
        agreementId: event.agreementId,
      );

      emit(AgreementDetailLoaded(
        agreement: agreement,
        groupId: event.groupId,
      ));
    } on AgreementApiException catch (e) {
      emit(AgreementDetailError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(AgreementDetailError(message: e.toString()));
    }
  }

  Future<void> _onUpdateAgreementStatus(
    UpdateAgreementStatus event,
    Emitter<AgreementDetailState> emit,
  ) async {
    if (_currentGroupId == null || _currentAgreementId == null) return;

    final agreement = state.agreementOrNull;
    if (agreement == null) return;

    emit(AgreementStatusUpdating(agreement: agreement));

    try {
      final updatedAgreement = await _agreementProvider.updateAgreementStatus(
        groupId: _currentGroupId!,
        agreementId: _currentAgreementId!,
        status: event.newStatus,
      );

      emit(AgreementStatusUpdateSuccess(agreement: updatedAgreement));
    } on AgreementApiException catch (e) {
      emit(AgreementDetailError(message: e.message, code: e.code));
    } on Exception catch (e) {
      emit(AgreementDetailError(message: e.toString()));
    }
  }

  Future<void> _onTogglePin(
    TogglePin event,
    Emitter<AgreementDetailState> emit,
  ) async {
    if (_currentGroupId == null || _currentAgreementId == null) return;

    final agreement = state.agreementOrNull;
    if (agreement == null) return;

    emit(AgreementPinUpdating(agreement: agreement));

    try {
      if (event.currentPinStatus) {
        await _agreementProvider.unpinAgreement(
          groupId: _currentGroupId!,
          agreementId: _currentAgreementId!,
        );
      } else {
        await _agreementProvider.pinAgreement(
          groupId: _currentGroupId!,
          agreementId: _currentAgreementId!,
        );
      }

      final updatedAgreement =
          agreement.copyWith(isPinned: !event.currentPinStatus);

      emit(
        AgreementPinUpdateSuccess(
          agreement: updatedAgreement,
          isPinned: updatedAgreement.isPinned,
        ),
      );
    } on AgreementApiException catch (e) {
      emit(
        AgreementPinUpdateFailure(
          agreement: agreement,
          message: e.message,
          code: e.code,
        ),
      );
      emit(AgreementDetailLoaded(agreement: agreement, groupId: _currentGroupId!));
    } on Exception catch (e) {
      emit(
        AgreementPinUpdateFailure(
          agreement: agreement,
          message: e.toString(),
        ),
      );
      emit(AgreementDetailLoaded(agreement: agreement, groupId: _currentGroupId!));
    }
  }

}
