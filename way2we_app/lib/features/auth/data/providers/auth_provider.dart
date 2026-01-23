import 'package:dio/dio.dart';
import 'package:way2we_app/features/auth/data/models/models.dart';

/// Exception thrown when auth API operations fail.
class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthApiException: $message (code: $code)';
}

/// Provider for auth-related API calls.
class AuthProvider {
  AuthProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Sends a verification code to the specified target.
  ///
  /// [type] can be either 'phone' or 'email'.
  /// [target] is the phone number or email address.
  ///
  /// Throws [AuthApiException] if the request fails.
  Future<VerificationCodeResponse> sendVerificationCode({
    required String type,
    required String target,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/verification-code',
        data: VerificationCodeRequest(type: type, target: target).toJson(),
      );

      if (response.data == null) {
        throw const AuthApiException('Unexpected null response');
      }

      return VerificationCodeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw AuthApiException(
          data['message'] as String? ?? 'Unknown error',
          code: data['code'] as String?,
        );
      }
      throw AuthApiException(e.message ?? 'Network error');
    }
  }

  /// Registers a new user.
  Future<void> register({
    required String type,
    required String target,
    required String code,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/auth/register',
        data: {
          'type': type,
          'target': target,
          'code': code,
          'password': password,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw AuthApiException(
          data['message'] as String? ?? 'Unknown error',
          code: data['code'] as String?,
        );
      }
      throw AuthApiException(e.message ?? 'Network error');
    }
  }

  /// Logs in a user.
  Future<void> login({
    required String type,
    required String target,
    required String mode,
    required String credential,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {
          'type': type,
          'target': target,
          'mode': mode,
          'credential': credential,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        throw AuthApiException(
          data['message'] as String? ?? 'Unknown error',
          code: data['code'] as String?,
        );
      }
      throw AuthApiException(e.message ?? 'Network error');
    }
  }
}
