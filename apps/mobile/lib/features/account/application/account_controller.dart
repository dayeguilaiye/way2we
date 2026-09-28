import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/network/failure.dart';
import '../data/account_repository.dart';

final accountRepositoryProvider = Provider(
  (ref) => AccountRepository(ref.watch(apiProvider)),
);
final intentStoreProvider = Provider<IntentStore>(
  (ref) => const SecureIntentStore(FlutterSecureStorage()),
);

class AccountState {
  const AccountState({
    this.user,
    this.loading = false,
    this.busy = false,
    this.failure,
    this.pending,
  });
  final AccountUser? user;
  final bool loading, busy;
  final AppFailure? failure;
  final ProfileIntent? pending;
}

class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() {
    final sessions = ref.watch(sessionProvider);
    void changed() {
      state = const AccountState();
      ref.read(themeProvider.notifier).select(AppTheme.apricot);
      if (sessions.current != null) {
        unawaited(load());
      }
    }

    sessions.addListener(changed);
    ref.onDispose(() => sessions.removeListener(changed));
    if (sessions.current != null) {
      Future.microtask(load);
    }
    return const AccountState();
  }

  bool _current(int generation) =>
      ref.mounted && ref.read(sessionProvider).generation == generation;
  Future<void> load() async {
    final sessions = ref.read(sessionProvider);
    final id = sessions.current?.userId;
    if (id == null) return;
    final generation = sessions.generation;
    state = AccountState(
      user: state.user,
      loading: true,
      pending: state.pending,
    );
    try {
      final pending = await ref.read(intentStoreProvider).read(id);
      if (!_current(generation)) return;
      state = AccountState(user: state.user, loading: true, pending: pending);
      final user = await ref.read(accountRepositoryProvider).me();
      if (!_current(generation)) return;
      state = AccountState(user: user, pending: pending);
      ref.read(themeProvider.notifier).select(user.theme);
    } on AppFailure catch (error) {
      if (_current(generation)) {
        state = AccountState(
          user: state.user,
          failure: error,
          pending: state.pending,
        );
      }
    }
  }

  Future<bool> save(Map<String, String> change) async {
    if (state.busy ||
        state.loading ||
        state.pending != null ||
        state.user == null) {
      return false;
    }
    final intent = ProfileIntent(operationKey(), Map.unmodifiable(change));
    return _submit(intent);
  }

  Future<bool> retry() async {
    final intent = state.pending;
    return intent != null && !state.busy ? _submit(intent) : false;
  }

  Future<bool> _submit(ProfileIntent intent) async {
    final sessions = ref.read(sessionProvider);
    final id = sessions.current?.userId;
    if (id == null) return false;
    final generation = sessions.generation;
    final store = ref.read(intentStoreProvider);
    state = AccountState(user: state.user, busy: true, pending: intent);
    try {
      // Persist before sending so a lost response or restart keeps the same operation key.
      await store.write(id, intent);
      if (!_current(generation)) return false;
      final saved = await ref.read(accountRepositoryProvider).update(intent);
      if (!_current(generation)) return false;
      // Replay returns the original snapshot; read current data before displaying it.
      final current = await ref.read(accountRepositoryProvider).me();
      if (current.id != saved.id) throw const ProtocolFailure();
      await store.write(id, null);
      if (!_current(generation)) return false;
      state = AccountState(user: current);
      ref.read(themeProvider.notifier).select(current.theme);
      return true;
    } on AppFailure catch (error) {
      if (!_current(generation)) return false;
      final pending = intent;
      if (error case ApiFailure(:final status)
          when status == 400 || status == 422) {
        try {
          await store.write(id, null);
          if (_current(generation)) {
            state = AccountState(user: state.user, failure: error);
          }
          return false;
        } on AppFailure {
          /* Keep the recoverable intent when local cleanup fails. */
        }
      }
      state = AccountState(user: state.user, failure: error, pending: pending);
      return false;
    }
  }

  Future<bool> logout() async {
    if (state.busy) return false;
    final sessions = ref.read(sessionProvider);
    final generation = sessions.generation;
    state = AccountState(user: state.user, busy: true, pending: state.pending);
    try {
      try {
        await ref.read(accountRepositoryProvider).logout();
      } on ApiFailure catch (error) {
        if (error.code != 'UNAUTHENTICATED') rethrow;
      }
      if (_current(generation)) {
        await sessions.set(null);
      }
      return true;
    } on AppFailure catch (error) {
      if (_current(generation)) {
        state = AccountState(
          user: state.user,
          pending: state.pending,
          failure: error,
        );
      }
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = AccountState(
          user: state.user,
          failure: const StorageFailure(),
          pending: state.pending,
        );
      }
      return false;
    }
  }
}

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

class LoginState {
  const LoginState({
    this.busy = false,
    this.email,
    this.resendAt,
    this.failure,
  });
  final bool busy;
  final String? email;
  final DateTime? resendAt;
  final AppFailure? failure;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();
  void editEmail() {
    if (!state.busy) state = const LoginState();
  }

  Future<void> send(String email) async {
    if (state.busy) return;
    state = LoginState(
      busy: true,
      email: state.email,
      resendAt: state.resendAt,
    );
    try {
      final seconds = await ref
          .read(accountRepositoryProvider)
          .sendCode(email.trim());
      if (ref.mounted) {
        state = LoginState(
          email: email.trim(),
          resendAt: DateTime.now().add(Duration(seconds: seconds)),
        );
      }
    } on AppFailure catch (error) {
      if (ref.mounted) {
        state = LoginState(
          email: state.email,
          resendAt: error is ApiFailure && error.status == 429
              ? DateTime.now().add(
                  Duration(
                    seconds: (error.retryAfterSeconds ?? 60).clamp(1, 3600),
                  ),
                )
              : state.resendAt,
          failure: error,
        );
      }
    }
  }

  Future<void> login(String code) async {
    final email = state.email;
    if (state.busy || email == null) return;
    state = LoginState(busy: true, email: email, resendAt: state.resendAt);
    try {
      final result = await ref
          .read(accountRepositoryProvider)
          .login(email, code);
      try {
        await ref.read(sessionProvider).establish(result.session);
      } catch (_) {
        throw const StorageFailure();
      }
      if (ref.mounted) {
        state = const LoginState();
      }
    } on AppFailure catch (error) {
      if (ref.mounted) {
        state = LoginState(
          email: email,
          resendAt: state.resendAt,
          failure: error,
        );
      }
    }
  }
}

final loginProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
