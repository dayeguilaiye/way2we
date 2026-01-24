part of 'profile_bloc.dart';

/// Sealed class for ProfileState to distinguish different success scenarios.
///
/// This pattern allows us to clearly differentiate between:
/// - Initial loading (ProfileLoadSuccess) - should NOT show success toast
/// - User-triggered update (ProfileUpdateSuccess) - SHOULD show success toast
/// - Failure states with error codes for proper handling
sealed class ProfileState extends Equatable {
  const ProfileState({
    this.nickname = '',
    this.avatarUrl = '',
  });

  final String nickname;
  final String avatarUrl;

  @override
  List<Object?> get props => [nickname, avatarUrl];
}

/// Initial state before any data is loaded.
final class ProfileInitial extends ProfileState {
  const ProfileInitial() : super();
}

/// Loading state while fetching or updating profile.
final class ProfileLoading extends ProfileState {
  const ProfileLoading({
    super.nickname,
    super.avatarUrl,
  });
}

/// Success state after initial profile load.
/// UI should NOT show success toast for this state.
final class ProfileLoadSuccess extends ProfileState {
  const ProfileLoadSuccess({
    required super.nickname,
    required super.avatarUrl,
  });
}

/// Success state after user-triggered profile update.
/// UI SHOULD show success toast for this state.
final class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess({
    required super.nickname,
    required super.avatarUrl,
  });
}

/// Failure state with error information.
final class ProfileFailure extends ProfileState {
  const ProfileFailure({
    required this.errorCode,
    required this.errorMessage,
    super.nickname,
    super.avatarUrl,
  });

  /// Machine-readable error code for frontend mapping.
  final String? errorCode;

  /// Human-readable error message (for debugging/fallback).
  final String errorMessage;

  @override
  List<Object?> get props => [nickname, avatarUrl, errorCode, errorMessage];
}
