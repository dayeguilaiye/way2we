import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2we/core/network/api_client.dart';
import 'package:way2we/core/network/failure.dart';
import 'package:way2we/core/session/session.dart';

class MemoryStore implements SessionStore {
  Session? value;
  @override
  Future<Session?> read() async => value;
  @override
  Future<void> write(Session? session) async {
    value = session;
  }
}

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody errorBody(String code, {int status = 401}) =>
    ResponseBody.fromString(
      jsonEncode({
        'error': {
          'code': code,
          'message': 'server-controlled text',
          'field_errors': <Object?>[],
        },
        'request_id': 'request-1',
      }),
      status,
      headers: {
        'content-type': ['application/json'],
        'x-request-id': ['request-1'],
      },
    );
void main() {
  test('secure deletion failure is typed and clears active identity', () async {
    final session = SessionController(FailingDeleteStore());
    addTearDown(session.dispose);
    await session.set(const Session(userId: 'a', token: 'token'));
    final dio = createDio('https://example.test');
    addTearDown(dio.close);
    dio.httpClientAdapter = Adapter((_) async => errorBody('UNAUTHENTICATED'));
    await expectLater(
      ApiClient(dio, session).request('/v1/me'),
      throwsA(isA<StorageFailure>()),
    );
    expect(session.current, isNull);
  });

  test(
    'multiple business 401s expire once; old responses preserve new login',
    () async {
      final session = SessionController(MemoryStore());
      addTearDown(session.dispose);
      await session.set(const Session(userId: 'a', token: 'secret-a'));
      var notices = 0;
      session.addListener(() => notices++);
      final gate = Completer<void>();
      final dio = createDio('https://example.test');
      addTearDown(dio.close);
      dio.httpClientAdapter = Adapter((options) async {
        await gate.future;
        return errorBody('UNAUTHENTICATED');
      });
      final api = ApiClient(dio, session);
      final one = expectLater(
        api.request('/v1/me'),
        throwsA(isA<ApiFailure>()),
      );
      final two = expectLater(
        api.request('/v1/me'),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await Future.wait([one, two]);
      expect(session.current, isNull);
      expect(notices, 1);
      await session.set(const Session(userId: 'a', token: 'old'));
      final stale = Completer<ResponseBody>();
      dio.httpClientAdapter = Adapter((_) => stale.future);
      final pending = expectLater(
        api.request('/v1/me'),
        throwsA(isA<ApiFailure>()),
      );
      await Future<void>.delayed(Duration.zero);
      await session.set(const Session(userId: 'b', token: 'new'));
      stale.complete(errorBody('UNAUTHENTICATED'));
      await pending;
      expect(session.current?.userId, 'b');
    },
  );
  test('public code failure preserves session and sends no bearer', () async {
    final session = SessionController(MemoryStore());
    addTearDown(session.dispose);
    await session.set(const Session(userId: 'a', token: 'secret'));
    final dio = createDio('https://example.test');
    addTearDown(dio.close);
    dio.httpClientAdapter = Adapter((options) async {
      expect(options.headers.containsKey('Authorization'), false);
      return errorBody('CODE_INVALID_OR_EXPIRED');
    });
    await expectLater(
      ApiClient(dio, session).request('/v1/sessions', authenticated: false),
      throwsA(isA<ApiFailure>()),
    );
    expect(session.current?.userId, 'a');
  });
  test('unknown errors use local copy; malformed responses become protocol failures', () async {
    final session = SessionController(MemoryStore());
    addTearDown(session.dispose);
    final dio = createDio('https://example.test');
    addTearDown(dio.close);
    final api = ApiClient(dio, session);
    dio.httpClientAdapter = Adapter(
      (_) async => errorBody('FUTURE_ERROR', status: 409),
    );
    try {
      await api.request('/v1/test');
      fail('expected error');
    } on ApiFailure catch (e) {
      expect(failureMessage(e), '暂时无法完成，请稍后重试。');
      expect(e.requestId, 'request-1');
    }
    for (final value in [
      '<html>Bad gateway</html>',
      jsonEncode({
        'error': {'code': 'INVALID'},
      }),
    ]) {
      dio.httpClientAdapter = Adapter(
        (_) async => ResponseBody.fromString(value, 502),
      );
      await expectLater(
        api.request('/v1/test'),
        throwsA(isA<ProtocolFailure>()),
      );
    }
  });
  test('timeouts are typed and one intent keeps its idempotency key', () async {
    final session = SessionController(MemoryStore());
    addTearDown(session.dispose);
    final dio = createDio('https://example.test');
    addTearDown(dio.close);
    var attempts = 0;
    dio.httpClientAdapter = Adapter((options) async {
      attempts++;
      expect(options.headers['Idempotency-Key'], 'same-intent');
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    });
    final api = ApiClient(dio, session);
    for (var i = 0; i < 2; i++) {
      await expectLater(
        api.request('/v1/write', method: 'POST', idempotencyKey: 'same-intent'),
        throwsA(isA<TimeoutFailure>()),
      );
    }
    expect(attempts, 2);
  });
}

class FailingDeleteStore extends MemoryStore {
  @override
  Future<void> write(Session? session) async {
    if (session == null) throw StateError('injected local storage failure');
    await super.write(session);
  }
}
