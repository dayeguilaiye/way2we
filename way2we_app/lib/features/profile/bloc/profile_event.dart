part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load the current user profile.
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Update profile with new nickname and/or avatar.
class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({
    this.nickname,
    this.avatarFile,
  });

  final String? nickname;
  final XFile? avatarFile;

  @override
  List<Object?> get props => [nickname, avatarFile];
}
