import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  const Session({required this.userId, required this.token});
  final String userId;
  final String token;
}

abstract interface class SessionStore {
  Future<Session?> read();
  Future<void> write(Session? session);
}

class SecureSessionStore implements SessionStore {
  const SecureSessionStore(this.storage);
  final FlutterSecureStorage storage;
  static const _key = 'way2we.session.v1';
  @override
  Future<Session?> read() async {
    final raw = await storage.read(key: _key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data
          case {'user_id': final String userId, 'token': final String token}
          when userId.isNotEmpty && token.isNotEmpty) {
        return Session(userId: userId, token: token);
      }
    } on FormatException {
      /* Clear malformed local data and require sign-in. */
    }
    await storage.delete(key: _key);
    return null;
  }

  @override
  Future<void> write(Session? session) async {
    if (session == null) {
      await storage.delete(key: _key);
      return;
    }
    await storage.write(
      key: _key,
      value: jsonEncode({'user_id': session.userId, 'token': session.token}),
    );
  }
}

// Generation identifies the exact account/session that started a request.
// Storage operations are serialized so a delayed logout cannot erase a new login.
class SessionController extends ChangeNotifier {
  SessionController(this.store);
  final SessionStore store;
  Session? _current;
  int _generation = 0;
  Future<void> _writes = Future<void>.value();
  Session? get current => _current;
  int get generation => _generation;
  Future<void> restore() async {
    final started = _generation;
    final restored = await store.read();
    if (started != _generation) return;
    _current = restored;
    _generation++;
    notifyListeners();
  }

  Future<void> set(Session? session) {
    _current = session;
    _generation++;
    notifyListeners();
    final write = _writes.then((_) => store.write(session));
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  Future<void> expire(int generation) async {
    if (generation != _generation || _current == null) return;
    await set(null);
  }
}
