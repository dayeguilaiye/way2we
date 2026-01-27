import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

/// Exception thrown when profile API operations fail.
class ProfileApiException implements Exception {
  const ProfileApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ProfileApiException: $message (code: $code)';
}

/// Provider for profile-related API calls.
class ProfileProvider {
  ProfileProvider({
    required Dio dio,
    FlutterSecureStorage? storage,
  }) : _dio = dio,
       _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  /// Gets the current user profile.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data == null) {
        throw const ProfileApiException('Unexpected null response');
      }

      return response.data!;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates the user profile (nickname and/or avatar URL).
  Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (avatar != null) data['avatar'] = avatar;

      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/users/me',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data == null) {
        throw const ProfileApiException('Unexpected null response');
      }

      return response.data!;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Uploads an avatar image and returns the URL.
  Future<String> uploadAvatar(XFile imageFile) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final mimeType = imageFile.mimeType;

      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(
          await imageFile.readAsBytes(),
          filename: imageFile.name,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/uploads/avatar',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data == null) {
        throw const ProfileApiException('Unexpected null response');
      }

      return response.data!['url'] as String;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw ProfileApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw ProfileApiException(e.message ?? 'Network error');
  }
}
