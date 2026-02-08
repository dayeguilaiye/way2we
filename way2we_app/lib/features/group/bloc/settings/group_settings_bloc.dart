import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'group_settings_event.dart';
part 'group_settings_state.dart';

class GroupSettingsBloc extends Bloc<GroupSettingsEvent, GroupSettingsState> {
  GroupSettingsBloc({required GroupProvider groupProvider})
    : _groupProvider = groupProvider,
      super(GroupSettingsInitial()) {
    on<LoadGroupSettings>(_onLoadGroupSettings);
    on<UpdateGroupSettings>(_onUpdateGroupSettings);
  }

  final GroupProvider _groupProvider;

  Future<void> _onLoadGroupSettings(
    LoadGroupSettings event,
    Emitter<GroupSettingsState> emit,
  ) async {
    emit(GroupSettingsLoading());
    try {
      final settings = await _groupProvider.getGroupSettings(
        groupId: event.groupId,
      );
      emit(GroupSettingsLoaded(settings));
    } on Object catch (e) {
      final message = e is GroupApiException ? e.message : e.toString();
      emit(GroupSettingsError(message));
    }
  }

  Future<void> _onUpdateGroupSettings(
    UpdateGroupSettings event,
    Emitter<GroupSettingsState> emit,
  ) async {
    GroupSettings? currentSettings;
    if (state is GroupSettingsLoaded) {
      currentSettings = (state as GroupSettingsLoaded).settings;
      emit(GroupSettingsUpdating(currentSettings));
    } else if (state is GroupSettingsUpdateSuccess) {
      currentSettings = (state as GroupSettingsUpdateSuccess).settings;
      emit(GroupSettingsUpdating(currentSettings));
    } else {
      emit(GroupSettingsLoading());
    }

    try {
      final settings = await _groupProvider.updateGroupSettings(
        groupId: event.groupId,
        settings: event.settings,
      );
      emit(GroupSettingsUpdateSuccess(settings));
    } on Object catch (e) {
      final message = e is GroupApiException ? e.message : e.toString();
      emit(GroupSettingsError(message, settings: currentSettings));
    }
  }
}
