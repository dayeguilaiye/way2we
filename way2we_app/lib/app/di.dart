import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:way2we_app/app/config.dart';
import 'package:way2we_app/features/auth/bloc/authentication_bloc.dart';

/// Service locator for dependency injection.
///
/// This provides a centralized place to create and access shared dependencies
/// like Dio, storage, etc. All dependencies should be created once and reused.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  Dio? _dio;
  FlutterSecureStorage? _storage;
  AuthenticationBloc? _authBloc;

  /// Initialize all dependencies. Call this once during app startup.
  void init() {
    _storage = const FlutterSecureStorage();
    _dio = _createDio();
  }

  /// Set the authentication bloc for 401 handling.
  /// This should be called after the bloc is created.
  // ignore: use_setters_to_change_properties
  void setAuthBloc(AuthenticationBloc bloc) {
    _authBloc = bloc;
  }

  /// Get the shared Dio instance.
  Dio get dio {
    if (_dio == null) {
      throw StateError('ServiceLocator not initialized. Call init() first.');
    }
    return _dio!;
  }

  /// Get the shared FlutterSecureStorage instance.
  FlutterSecureStorage get storage {
    if (_storage == null) {
      throw StateError('ServiceLocator not initialized. Call init() first.');
    }
    return _storage!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add auth token interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage!.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - trigger logout
          if (error.response?.statusCode == 401) {
            // Clear token and trigger logout
            await _storage!.delete(key: 'auth_token');
            _authBloc?.add(const AppLogoutRequested());
          }

          // Log errors in non-production mode
          if (!AppConfig.isProduction) {
            // ignore: avoid_print
            print('DioError: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Reset all dependencies. Useful for testing or logout.
  void reset() {
    _dio?.close();
    _dio = null;
    _storage = null;
    _authBloc = null;
  }
}
