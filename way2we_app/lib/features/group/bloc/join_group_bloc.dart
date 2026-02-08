import 'package:bloc/bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'join_group_event.dart';
part 'join_group_state.dart';

/// BLoC for managing join group operations.
class JoinGroupBloc extends Bloc<JoinGroupEvent, JoinGroupState> {
  JoinGroupBloc({
    required GroupProvider groupProvider,
  }) : _groupProvider = groupProvider,
       super(const JoinGroupState()) {
    on<JoinGroupCodeChanged>(_onCodeChanged);
    on<JoinGroupPreviewRequested>(_onPreviewRequested);
    on<JoinGroupConfirmed>(_onConfirmed);
  }

  final GroupProvider _groupProvider;

  void _onCodeChanged(
    JoinGroupCodeChanged event,
    Emitter<JoinGroupState> emit,
  ) {
    emit(
      state.copyWith(
        invitationCode: event.code.toUpperCase(),
        status: JoinGroupStatus.initial,
      ),
    );
  }

  Future<void> _onPreviewRequested(
    JoinGroupPreviewRequested event,
    Emitter<JoinGroupState> emit,
  ) async {
    if (!state.isCodeValid) return;

    emit(state.copyWith(status: JoinGroupStatus.loadingPreview));

    try {
      final response = await _groupProvider.getGroupByInvitation(
        code: state.invitationCode,
      );
      emit(
        state.copyWith(
          status: JoinGroupStatus.previewLoaded,
          groupId: response.id,
          groupName: response.name,
          memberCount: response.memberCount,
        ),
      );
    } on GroupApiException catch (e) {
      emit(
        state.copyWith(
          status: JoinGroupStatus.failure,
          errorMessage: e.message,
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: JoinGroupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConfirmed(
    JoinGroupConfirmed event,
    Emitter<JoinGroupState> emit,
  ) async {
    if (!state.hasPreview) return;

    emit(state.copyWith(status: JoinGroupStatus.joining));

    try {
      final response = await _groupProvider.joinGroup(
        invitationCode: state.invitationCode,
      );
      emit(
        state.copyWith(
          status: JoinGroupStatus.success,
          groupId: response.groupId,
          groupName: response.groupName,
          memberCount: response.memberCount,
        ),
      );
    } on GroupApiException catch (e) {
      emit(
        state.copyWith(
          status: JoinGroupStatus.failure,
          errorMessage: e.message,
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: JoinGroupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
