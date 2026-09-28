import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/app/providers.dart';
import 'package:way2we/core/network/api_client.dart';
import 'package:way2we/core/session/session.dart';
import 'package:way2we/features/spaces/application/space_controller.dart';
import 'package:way2we/features/spaces/data/space_repository.dart';

import 'api_client_test.dart' show MemoryStore, Adapter;

class MemoryOperations implements OperationStore {
  final values = <String, PendingOperation>{};
  @override
  Future<PendingOperation?> read(String uid) async => values[uid];
  @override
  Future<void> write(String uid, PendingOperation? v) async {
    if (v == null) {
      values.remove(uid);
    } else {
      values[uid] = v;
    }
  }
}

ResponseBody body(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    'content-type': ['application/json'],
  },
);
Future<void> ready(ProviderContainer c) async {
  c.read(operationProvider);
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    if (c.read(operationProvider).ready) return;
  }
  fail('not ready');
}

void main() {
  test(
    'uncertain space creation persists the original intent through restart',
    () async {
      final sessions = SessionController(MemoryStore());
      addTearDown(sessions.dispose);
      await sessions.set(const Session(userId: 'a', token: 'a'));
      final store = MemoryOperations();
      final dio = createDio('https://example.test');
      addTearDown(dio.close);
      final keys = <String>[];
      var timeout = true;
      dio.httpClientAdapter = Adapter((options) async {
        keys.add(options.headers['Idempotency-Key'] as String);
        if (timeout) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        }
        return body({
          'space': {'id': 'space-a'},
        });
      });
      ProviderContainer build() => ProviderContainer(
        overrides: [
          sessionProvider.overrideWithValue(sessions),
          apiProvider.overrideWithValue(ApiClient(dio, sessions)),
          operationStoreProvider.overrideWithValue(store),
        ],
      );
      var c = build();
      await ready(c);
      await c
          .read(operationProvider.notifier)
          .submit('/v1/spaces', data: {'name': '家', 'nickname': '甲'});
      expect(store.values['a'], isNotNull);
      expect(c.read(operationProvider).pending, isNotNull);
      expect(
        await c
            .read(operationProvider.notifier)
            .submit('/v1/spaces', data: {'name': '第二个'}),
        isNull,
      );
      c.dispose();
      c = build();
      addTearDown(c.dispose);
      await ready(c);
      timeout = false;
      final result = await c.read(operationProvider.notifier).retry();
      expect(result?['space'], {'id': 'space-a'});
      expect(keys.length, 2);
      expect(keys[0], keys[1]);
      expect(store.values, isEmpty);
    },
  );
  test(
    'late mutation and query responses cannot enter the next account',
    () async {
      final sessions = SessionController(MemoryStore());
      addTearDown(sessions.dispose);
      await sessions.set(const Session(userId: 'a', token: 'a'));
      final store = MemoryOperations();
      final dio = createDio('https://example.test');
      addTearDown(dio.close);
      final pending = Completer<ResponseBody>();
      final query = Completer<ResponseBody>();
      dio.httpClientAdapter = Adapter((o) async {
        if (o.method == 'POST') return pending.future;
        if (o.headers['Authorization'] == 'Bearer a') return query.future;
        return body({'items': <Object?>[], 'next_cursor': null});
      });
      final c = ProviderContainer(
        overrides: [
          sessionProvider.overrideWithValue(sessions),
          apiProvider.overrideWithValue(ApiClient(dio, sessions)),
          operationStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(c.dispose);
      await ready(c);
      final subscription = c.listen(spacesProvider(null), (_, _) {});
      addTearDown(subscription.close);
      final old = c
          .read(operationProvider.notifier)
          .submit('/v1/spaces', data: {'name': '家', 'nickname': '甲'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sessions.set(const Session(userId: 'b', token: 'b'));
      await ready(c);
      pending.complete(
        body({
          'space': {'id': 'a-secret'},
        }),
      );
      query.complete(
        body({
          'items': [
            {
              'space': {'id': 'a-secret', 'name': '甲的空间'},
              'my_member_id': 'a',
              'my_status': 'active',
            },
          ],
          'next_cursor': null,
        }),
      );
      expect(await old, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(operationProvider).result, isNull);
      expect((await c.read(spacesProvider(null).future)).items, isEmpty);
      expect(store.values['b'], isNull);
    },
  );
  test('paste code and links normalize without opening arbitrary URLs', () {
    expect(invitationCode('abcd-efgh-ijkl-mnop-qrst'), 'ABCDEFGHIJKLMNOPQRST');
    expect(
      invitationCode('way2we://app/join?code=ABCDEFGHIJKLMNOPQRST'),
      'ABCDEFGHIJKLMNOPQRST',
    );
    expect(
      invitationCode('https://example.test/invite?code=ABCDEFGHIJKLMNOPQRST'),
      'ABCDEFGHIJKLMNOPQRST',
    );
    expect(invitationCode('file:///etc/passwd'), isNull);
    expect(invitationCode('12345'), isNull);
  });
}
