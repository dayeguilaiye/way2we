import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/providers.dart';
import '../../../core/network/failure.dart';
import '../../account/data/account_repository.dart' show operationKey;
import '../data/space_repository.dart';
import '../data/models.dart';

final spaceRepositoryProvider = Provider(
  (ref) => SpaceRepository(ref.watch(apiProvider)),
);
final operationStoreProvider = Provider<OperationStore>(
  (ref) => const SecureOperationStore(FlutterSecureStorage()),
);
// A query instance belongs to one exact session. Old requests cannot enter a new account.
final sessionScopeProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionProvider);
  void changed() => ref.invalidateSelf();
  sessions.addListener(changed);
  ref.onDispose(() => sessions.removeListener(changed));
  return sessions.generation;
});
final spacesProvider = FutureProvider.autoDispose.family((ref, String? cursor) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).spaces(cursor);
});
final membersProvider = FutureProvider.autoDispose.family((
  ref,
  ({String id, String? cursor}) q,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).members(q.id, q.cursor);
});
final invitationsProvider = FutureProvider.autoDispose.family((
  ref,
  ({String id, String? cursor}) q,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).invitations(q.id, q.cursor);
});
final invitationProvider = FutureProvider.autoDispose.family((ref, String id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).invitation(id);
});
final spaceNameProvider = FutureProvider.autoDispose.family((ref, String id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).spaceName(id);
});
final noticesProvider = FutureProvider.autoDispose.family((
  ref,
  String? cursor,
) {
  ref.watch(sessionScopeProvider);
  return ref.watch(spaceRepositoryProvider).notices(cursor);
});

class OperationState {
  const OperationState({
    this.ready = false,
    this.busy = false,
    this.pending,
    this.failure,
    this.completed,
    this.result,
  });
  final bool ready, busy;
  final PendingOperation? pending, completed;
  final AppFailure? failure;
  final Map<String, dynamic>? result;
}

class OperationController extends Notifier<OperationState> {
  @override
  OperationState build() {
    ref.watch(sessionScopeProvider);
    Future.microtask(load);
    return const OperationState();
  }

  bool current(int gen) =>
      ref.mounted && ref.read(sessionProvider).generation == gen;
  Future<void> load() async {
    final session = ref.read(sessionProvider);
    final uid = session.current?.userId;
    if (uid == null) return;
    final gen = session.generation;
    try {
      final op = await ref.read(operationStoreProvider).read(uid);
      if (current(gen)) state = OperationState(ready: true, pending: op);
    } on AppFailure catch (e) {
      if (current(gen)) state = OperationState(failure: e);
    }
  }

  Future<Map<String, dynamic>?> submit(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? data,
  }) async {
    if (!state.ready || state.busy || state.pending != null) return null;
    final op = PendingOperation(
      key: operationKey(),
      path: path,
      method: method,
      data: data,
    );
    return _send(op);
  }

  Future<Map<String, dynamic>?> retry() async {
    final op = state.pending;
    if (op == null || state.busy) return null;
    return _send(op);
  }

  Future<Map<String, dynamic>?> _send(PendingOperation op) async {
    final sessions = ref.read(sessionProvider);
    final uid = sessions.current?.userId;
    if (uid == null) return null;
    final gen = sessions.generation;
    final store = ref.read(operationStoreProvider);
    final repo = ref.read(spaceRepositoryProvider);
    state = OperationState(ready: true, busy: true, pending: op);
    try {
      await store.write(uid, op);
      if (!current(gen)) return null;
      final result = await repo.command(op);
      await store.write(uid, null);
      if (!current(gen)) return null;
      state = OperationState(ready: true, completed: op, result: result);
      ref.invalidate(spacesProvider);
      ref.invalidate(membersProvider);
      ref.invalidate(approvalMembersProvider);
      ref.invalidate(invitationsProvider);
      ref.invalidate(invitationProvider);
      ref.invalidate(noticesProvider);
      return result;
    } on AppFailure catch (e) {
      final terminal =
          e is ApiFailure &&
          e.status < 500 &&
          e.status != 429 &&
          e.code != 'OPERATION_IN_PROGRESS';
      if (terminal) {
        try {
          await store.write(uid, null);
        } on AppFailure catch (storage) {
          if (current(gen)) {
            state = OperationState(ready: true, pending: op, failure: storage);
          }
          return null;
        }
      }
      if (current(gen)) {
        state = OperationState(
          ready: true,
          pending: terminal ? null : op,
          failure: e,
        );
      }
      return null;
    }
  }

  void dismissResult() {
    if (state.pending == null && !state.busy) {
      state = const OperationState(ready: true);
    }
  }
}

final operationProvider = NotifierProvider<OperationController, OperationState>(
  OperationController.new,
);

// Approval needs the current account even when it is beyond the first member page.
final approvalMembersProvider = FutureProvider.autoDispose
    .family<List<MemberInfo>, String>((ref, id) async {
      ref.watch(sessionScopeProvider);
      final repo = ref.watch(spaceRepositoryProvider);
      final items = <MemberInfo>[];
      String? cursor;
      do {
        final page = await repo.members(id, cursor);
        items.addAll(page.items);
        cursor = page.next;
      } while (cursor != null && ref.mounted);
      return List.unmodifiable(items);
    });
