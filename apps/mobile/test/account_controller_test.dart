import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/providers.dart';
import 'package:way2we/app/theme.dart';
import 'package:way2we/core/network/api_client.dart';
import 'package:way2we/core/session/session.dart';
import 'package:way2we/features/account/application/account_controller.dart';
import 'package:way2we/features/account/data/account_repository.dart';

import 'api_client_test.dart' show MemoryStore, Adapter;

class MemoryIntents implements IntentStore {
  final values = <String, ProfileIntent>{};
  @override
  Future<ProfileIntent?> read(String id) async => values[id];
  @override
  Future<void> write(String id, ProfileIntent? intent) async {
    if (intent == null) {
      values.remove(id);
    } else {
      values[id] = intent;
    }
  }
}

ResponseBody userBody(String id, String theme) => ResponseBody.fromString(
  jsonEncode({
    'id': id,
    'display_name': id,
    'theme': theme,
    'created_at': '2026-09-28T00:00:00Z',
  }),
  200,
  headers: {
    'content-type': ['application/json'],
  },
);
Future<void> settled(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    if (!container.read(accountProvider).loading) return;
  }
  fail('account did not settle');
}

void main() {
  test(
    'lost profile response survives restart and reuses persisted intent',
    () async {
      final sessions = SessionController(MemoryStore());
      addTearDown(sessions.dispose);
      await sessions.set(const Session(userId: 'a', token: 'token-a'));
      final intents = MemoryIntents();
      final dio = createDio('https://example.test');
      addTearDown(dio.close);
      final keys = <String>[];
      var theme = 'apricot';
      var fail = true;
      dio.httpClientAdapter = Adapter((options) async {
        if (options.method == 'PATCH') {
          keys.add(options.headers['Idempotency-Key'] as String);
          expect(intents.values['a']?.key, keys.last);
          theme = 'rose';
          if (fail) {
            fail = false;
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            );
          }
        }
        return userBody('a', theme);
      });
      ProviderContainer create() => ProviderContainer(
        overrides: [
          sessionProvider.overrideWithValue(sessions),
          apiProvider.overrideWithValue(ApiClient(dio, sessions)),
          intentStoreProvider.overrideWithValue(intents),
        ],
      );
      var container = create();
      container.read(accountProvider);
      await settled(container);
      expect(
        await container.read(accountProvider.notifier).save({'theme': 'rose'}),
        false,
      );
      expect(container.read(accountProvider).pending, isNotNull);
      expect(
        await container.read(accountProvider.notifier).save({
          'theme': 'celadon',
        }),
        false,
      );
      container.dispose();
      container = create();
      addTearDown(container.dispose);
      container.read(accountProvider);
      await settled(container);
      expect(container.read(accountProvider).pending?.key, keys.single);
      expect(await container.read(accountProvider.notifier).retry(), true);
      expect(keys.length, 2);
      expect(keys[0], keys[1]);
      expect(intents.values, isEmpty);
      expect(container.read(themeProvider), AppTheme.rose);
    },
  );
  test('late profile read cannot populate another account', () async {
    final sessions = SessionController(MemoryStore());
    addTearDown(sessions.dispose);
    await sessions.set(const Session(userId: 'a', token: 'token-a'));
    final dio = createDio('https://example.test');
    addTearDown(dio.close);
    final old = Completer<ResponseBody>();
    dio.httpClientAdapter = Adapter(
      (options) async => options.headers['Authorization'] == 'Bearer token-a'
          ? old.future
          : userBody('b', 'celadon'),
    );
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWithValue(sessions),
        apiProvider.overrideWithValue(ApiClient(dio, sessions)),
        intentStoreProvider.overrideWithValue(MemoryIntents()),
      ],
    );
    addTearDown(container.dispose);
    container.read(accountProvider);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await sessions.set(const Session(userId: 'b', token: 'token-b'));
    await settled(container);
    old.complete(userBody('a', 'rose'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(accountProvider).user?.id, 'b');
    expect(container.read(themeProvider), AppTheme.celadon);
  });
  test('credential is not published before secure storage succeeds', () async {
    final store = DelayedStore();
    final session = SessionController(store);
    addTearDown(session.dispose);
    final login = session.establish(const Session(userId: 'a', token: 'token'));
    expect(session.current, isNull);
    store.gate.complete();
    await login;
    expect(session.current?.userId, 'a');
  });
}

class DelayedStore implements SessionStore {
  final gate = Completer<void>();
  @override
  Future<Session?> read() async => null;
  @override
  Future<void> write(Session? value) => gate.future;
}
