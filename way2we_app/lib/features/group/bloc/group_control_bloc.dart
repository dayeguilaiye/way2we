import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'group_control_event.dart';
part 'group_control_state.dart';

class GroupControlBloc extends Bloc<GroupControlEvent, GroupControlState> {
  GroupControlBloc({required GroupProvider groupProvider})
    : _groupProvider = groupProvider,
      super(GroupControlInitial()) {
    on<GroupControlGroupsLoaded>(_onGroupsLoaded);
    on<GroupControlGroupSelected>(_onGroupSelected);
  }

  final GroupProvider _groupProvider;
  static const _kLastSelectedGroupId = 'last_selected_group_id';

  Future<void> _onGroupsLoaded(
    GroupControlGroupsLoaded event,
    Emitter<GroupControlState> emit,
  ) async {
    emit(GroupControlLoadInProgress());
    try {
      final response = await _groupProvider.getUserGroups();
      final groups = response.groups;

      if (groups.isEmpty) {
        emit(const GroupControlLoadSuccess(groups: []));
        return;
      }

      // Determine selection
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt(_kLastSelectedGroupId);

      UserGroup? selected;
      if (lastId != null) {
        try {
          selected = groups.firstWhere((g) => g.id == lastId);
        } catch (_) {
          // not found
        }
      }

      // Default to first if not found or no preference
      if (selected == null && groups.isNotEmpty) {
        selected = groups.first;
        await prefs.setInt(_kLastSelectedGroupId, selected.id);
      } else if (selected != null && lastId != selected.id) {
        // Should catch cases where selected was restored but we want to ensure persistence matches?
        // Actually logic above sets selected if found. If selected is not null, it matches lastId.
      }

      emit(GroupControlLoadSuccess(groups: groups, selectedGroup: selected));
    } catch (e) {
      emit(GroupControlLoadFailure(e.toString()));
    }
  }

  Future<void> _onGroupSelected(
    GroupControlGroupSelected event,
    Emitter<GroupControlState> emit,
  ) async {
    final currentState = state;
    if (currentState is GroupControlLoadSuccess) {
      // Validate group exists in current list
      try {
        final newSelection = currentState.groups.firstWhere(
          (g) => g.id == event.groupId,
        );

        // Persist
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLastSelectedGroupId, event.groupId);

        emit(currentState.copyWith(selectedGroup: newSelection));
      } catch (_) {
        // Should not happen if inputs are valid, ignore
      }
    }
  }
}
