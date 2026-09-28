import 'package:dio/dio.dart';

import '../session/session.dart';
import 'failure.dart';

class ApiClient {
  ApiClient(this.dio, this.sessions);
  final Dio dio;
  final SessionController sessions;

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    bool authenticated = true,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    final generation = sessions.generation;
    final token = authenticated ? sessions.current?.token : null;
    try {
      final response = await dio.request<Object?>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          validateStatus: (_) => true,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Idempotency-Key': ?idempotencyKey,
          },
        ),
      );
      final id = response.headers.value('x-request-id');
      if (response.statusCode == 204) return {};
      final body = response.data;
      if (body is! Map<String, dynamic>) throw ProtocolFailure(requestId: id);
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return body;
      final error = body['error'];
      if (error is! Map<String, dynamic> ||
          error['code'] is! String ||
          error['message'] is! String ||
          error['field_errors'] is! List<Object?> ||
          body['request_id'] is! String) {
        throw ProtocolFailure(requestId: id);
      }
      final fields = <String, String>{};
      for (final item in error['field_errors'] as List<Object?>) {
        if (item case {
          'field': final String field,
          'code': final String code,
        }) {
          fields[field] = code;
        } else {
          throw ProtocolFailure(requestId: id);
        }
      }
      final code = error['code'] as String;
      if (authenticated && status == 401 && code == 'UNAUTHENTICATED') {
        try {
          await sessions.expire(generation);
        } catch (_) {
          throw const StorageFailure();
        }
      }
      throw ApiFailure(
        code: code,
        status: status,
        fields: Map.unmodifiable(fields),
        retryAfterSeconds: int.tryParse(
          response.headers.value('retry-after') ?? '',
        ),
        requestId: body['request_id'] as String,
      );
    } on DioException catch (error) {
      throw switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const TimeoutFailure(),
        DioExceptionType.cancel => const CancelledFailure(),
        DioExceptionType.unknown when error.error is FormatException =>
          const ProtocolFailure(),
        _ => const NetworkFailure(),
      };
    }
  }
}

Dio createDio(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  const release = bool.fromEnvironment('dart.vm.product');
  if (uri == null ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      !(uri.scheme == 'https' || !release && uri.scheme == 'http')) {
    throw ArgumentError(
      'API_BASE_URL must be a valid HTTPS origin (debug allows HTTP)',
    );
  }
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
    ),
  );
}
