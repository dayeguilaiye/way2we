part of 'authentication_bloc.dart';

/// Authentication states using sealed class for explicit state handling.
/// Authentication states using sealed class for explicit state handling.
sealed class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before authentication check.
final class AuthenticationInitial extends AuthenticationState {
  const AuthenticationInitial();
}

/// State when user is authenticated.
final class AuthenticationAuthenticated extends AuthenticationState {
  const AuthenticationAuthenticated({
    this.needsOnboarding = false,
    this.hasGroup = false,
  });

  final bool needsOnboarding;
  final bool hasGroup;

  @override
  List<Object?> get props => [needsOnboarding, hasGroup];
}

/// State when user is not authenticated.
final class AuthenticationUnauthenticated extends AuthenticationState {
  const AuthenticationUnauthenticated();
}
