part of 'authentication_bloc.dart';

/// Authentication events.
sealed class AuthenticationEvent {
  const AuthenticationEvent();
}

/// Event triggered when app starts to check authentication status.
final class AppStarted extends AuthenticationEvent {
  const AppStarted();
}

/// Event triggered when user requests to logout.
final class AppLogoutRequested extends AuthenticationEvent {
  const AppLogoutRequested();
}

/// Event triggered when user successfully logs in.
final class AppLoginSucceeded extends AuthenticationEvent {
  const AppLoginSucceeded({this.needsOnboarding = false});

  final bool needsOnboarding;
}
