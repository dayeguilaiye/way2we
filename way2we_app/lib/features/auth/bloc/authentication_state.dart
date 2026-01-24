part of 'authentication_bloc.dart';

/// Authentication states using sealed class for explicit state handling.
sealed class AuthenticationState {
  const AuthenticationState();
}

/// Initial state before authentication check.
final class AuthenticationInitial extends AuthenticationState {
  const AuthenticationInitial();
}

/// State when user is authenticated.
final class AuthenticationAuthenticated extends AuthenticationState {
  const AuthenticationAuthenticated({this.needsOnboarding = false});

  final bool needsOnboarding;
}

/// State when user is not authenticated.
final class AuthenticationUnauthenticated extends AuthenticationState {
  const AuthenticationUnauthenticated();
}
