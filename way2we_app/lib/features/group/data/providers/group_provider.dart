import 'package:dio/dio.dart';

/// Exception thrown when group API operations fail.
class GroupApiException implements Exception {
  const GroupApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'GroupApiException: $message (code: $code)';
}

/// Response model for create group API.
class CreateGroupResponse {
  const CreateGroupResponse({
    required this.id,
    required this.name,
    required this.role,
  });

  factory CreateGroupResponse.fromJson(Map<String, dynamic> json) {
    return CreateGroupResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  final int id;
  final String name;
  final String role;
}

/// Provider for group-related API calls.
class GroupProvider {
  GroupProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Creates a new group with the given name.
  /// The current user becomes the admin of the group.
  Future<CreateGroupResponse> createGroup({required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups',
        data: {'name': name},
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return CreateGroupResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw GroupApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw GroupApiException(e.message ?? 'Network error');
  }
}
