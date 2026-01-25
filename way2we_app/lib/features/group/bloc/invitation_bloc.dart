import 'package:bloc/bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'invitation_event.dart';
part 'invitation_state.dart';

/// BLoC for managing invitation code operations.
class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  InvitationBloc({
    required GroupProvider groupProvider,
    required int groupId,
  })  : _groupProvider = groupProvider,
        _groupId = groupId,
        super(const InvitationState()) {
    on<InvitationLoadRequested>(_onLoadRequested);
    on<InvitationRefreshRequested>(_onRefreshRequested);
    on<InvitationCopyRequested>(_onCopyRequested);
  }

  final GroupProvider _groupProvider;
  final int _groupId;

  Future<void> _onLoadRequested(
    InvitationLoadRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(state.copyWith(status: InvitationStatus.loading));

    try {
      final response =
          await _groupProvider.getInvitationCode(groupId: _groupId);
      emit(state.copyWith(
        status: InvitationStatus.loaded,
        invitationCode: response.invitationCode,
        shareUrl: response.shareUrl,
      ));
    } on GroupApiException catch (e) {
      emit(state.copyWith(
        status: InvitationStatus.failure,
        errorMessage: e.message,
        errorCode: e.code,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: InvitationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    InvitationRefreshRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(state.copyWith(status: InvitationStatus.refreshing));

    try {
      final response =
          await _groupProvider.refreshInvitationCode(groupId: _groupId);
      emit(state.copyWith(
        status: InvitationStatus.refreshed,
        invitationCode: response.invitationCode,
        shareUrl: response.shareUrl,
      ));
    } on GroupApiException catch (e) {
      emit(state.copyWith(
        status: InvitationStatus.failure,
        errorMessage: e.message,
        errorCode: e.code,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: InvitationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCopyRequested(
    InvitationCopyRequested event,
    Emitter<InvitationState> emit,
  ) {
    emit(state.copyWith(status: InvitationStatus.copied));
  }
}
