import 'package:bloc/bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// BLoC for managing global authentication state.
///
/// This is the single source of truth for session state.
/// It handles:
/// - Checking authentication on app startup
/// - Logout requests
/// - Login success notifications
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthProvider authProvider,
  }) : _authProvider = authProvider,
       super(const AuthenticationInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppLoginSucceeded>(_onLoginSucceeded);
  }

  final AuthProvider _authProvider;

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    // Check if we have a stored token
    final token = await _authProvider.getToken();

    if (token != null && token.isNotEmpty) {
      emit(const AuthenticationAuthenticated());
    } else {
      emit(const AuthenticationUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AppLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _authProvider.logout();
    emit(const AuthenticationUnauthenticated());
  }

  void _onLoginSucceeded(
    AppLoginSucceeded event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(AuthenticationAuthenticated(needsOnboarding: event.needsOnboarding));
  }
}
