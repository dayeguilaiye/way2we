import 'package:bloc/bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'create_group_event.dart';
part 'create_group_state.dart';

/// BLoC for managing the create group form state.
class CreateGroupBloc extends Bloc<CreateGroupEvent, CreateGroupState> {
  CreateGroupBloc({
    required GroupProvider groupProvider,
  }) : _groupProvider = groupProvider,
       super(const CreateGroupState()) {
    on<CreateGroupNameChanged>(_onNameChanged);
    on<CreateGroupSubmitted>(_onSubmitted);
  }

  final GroupProvider _groupProvider;

  void _onNameChanged(
    CreateGroupNameChanged event,
    Emitter<CreateGroupState> emit,
  ) {
    emit(state.copyWith(
      name: event.name,
    ));
  }

  Future<void> _onSubmitted(
    CreateGroupSubmitted event,
    Emitter<CreateGroupState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: CreateGroupStatus.submitting));

    try {
      final response = await _groupProvider.createGroup(name: state.name);
      emit(state.copyWith(
        status: CreateGroupStatus.success,
        groupId: response.id,
      ));
    } on GroupApiException catch (e) {
      emit(state.copyWith(
        status: CreateGroupStatus.failure,
        errorMessage: e.message,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: CreateGroupStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
