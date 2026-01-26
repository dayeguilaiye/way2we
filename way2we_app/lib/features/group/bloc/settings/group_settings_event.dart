part of 'group_settings_bloc.dart';

sealed class GroupSettingsEvent extends Equatable {
  const GroupSettingsEvent();

  @override
  List<Object> get props => [];
}

final class LoadGroupSettings extends GroupSettingsEvent {
  const LoadGroupSettings({required this.groupId});
  final int groupId;

  @override
  List<Object> get props => [groupId];
}

final class UpdateGroupSettings extends GroupSettingsEvent {
  const UpdateGroupSettings({
    required this.groupId,
    required this.settings,
  });
  final int groupId;
  final Map<String, dynamic> settings;

  @override
  List<Object> get props => [groupId, settings];
}
