import 'package:bloc/bloc.dart';
import 'package:way2we_app/features/auth/data/providers/auth_provider.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// BLoC for managing global authentication state.
///
/// This is the single source of truth for session state.
/// It handles:
/// - Checking authentication on app startup
/// - Logout requests
/// - Login success notifications
/// - Checking if user has a group
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthProvider authProvider,
    required GroupProvider groupProvider,
  })  : _authProvider = authProvider,
        _groupProvider = groupProvider,
        super(const AuthenticationInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppLoginSucceeded>(_onLoginSucceeded);
  }

  final AuthProvider _authProvider;
  final GroupProvider _groupProvider;

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    // Check if we have a stored token
    final token = await _authProvider.getToken();

    if (token != null && token.isNotEmpty) {
      // Check if user has any groups
      final hasGroup = await _checkHasGroup();
      emit(AuthenticationAuthenticated(hasGroup: hasGroup));
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
    // New users won't have a group yet
    emit(AuthenticationAuthenticated(
      needsOnboarding: event.needsOnboarding,
    ));
  }

  /// Check if the current user has any groups.
  Future<bool> _checkHasGroup() async {
    try {
      final response = await _groupProvider.getUserGroups();
      return response.groups.isNotEmpty;
    } on Exception {
      // If we can't check, assume no groups
      return false;
    }
  }
}
