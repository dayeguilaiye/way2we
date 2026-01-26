part of 'group_settings_bloc.dart';

sealed class GroupSettingsState extends Equatable {
  const GroupSettingsState();

  @override
  List<Object?> get props => [];
}

final class GroupSettingsInitial extends GroupSettingsState {}

final class GroupSettingsLoading extends GroupSettingsState {}

final class GroupSettingsLoaded extends GroupSettingsState {
  const GroupSettingsLoaded(this.settings);
  final GroupSettings settings;

  @override
  List<Object?> get props => [settings];
}

final class GroupSettingsUpdating extends GroupSettingsState {
  const GroupSettingsUpdating(this.currentSettings);
  final GroupSettings currentSettings;

  @override
  List<Object?> get props => [currentSettings];
}

final class GroupSettingsUpdateSuccess extends GroupSettingsState {
  const GroupSettingsUpdateSuccess(this.settings);
  final GroupSettings settings;

  @override
  List<Object?> get props => [settings];
}

final class GroupSettingsError extends GroupSettingsState {
  const GroupSettingsError(this.message, {this.settings});
  final String message;
  final GroupSettings? settings;

  @override
  List<Object?> get props => [message, settings];
}
