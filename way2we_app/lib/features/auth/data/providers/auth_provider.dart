import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  AuthProvider({
    required Dio dio,
    FlutterSecureStorage? storage,
  }) : _dio = dio,
       _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  /// Sends a verification code to the specified target.
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
      _handleDioError(e);
    }
  }

  /// Registers a new user and auto-login.
  Future<dynamic> register({
    required String type,
    required String target,
    required String code,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/register',
        data: {
          'type': type,
          'target': target,
          'code': code,
          'password': password,
        },
      );

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Logs in a user.
  Future<dynamic> login({
    required String type,
    required String target,
    required String mode,
    required String credential,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {
          'type': type,
          'target': target,
          'mode': mode,
          'credential': credential,
        },
      );

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Handles auth response, saves token, and returns user data.
  Future<dynamic> _handleAuthResponse(Map<String, dynamic>? data) async {
    if (data == null) {
      throw const AuthApiException('Unexpected null response');
    }

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: token);
    }

    return data['user'];
  }

  Never _handleDioError(DioException e) {
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
