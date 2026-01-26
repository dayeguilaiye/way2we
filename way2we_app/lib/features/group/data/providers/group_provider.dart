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

/// Response model for invitation code API.
class InvitationResponse {
  const InvitationResponse({
    required this.groupId,
    required this.invitationCode,
    required this.shareUrl,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      groupId: json['group_id'] as int,
      invitationCode: json['invitation_code'] as String,
      shareUrl: json['share_url'] as String,
    );
  }

  final int groupId;
  final String invitationCode;
  final String shareUrl;
}

/// Response model for group preview (by invitation code).
class GroupPreviewResponse {
  const GroupPreviewResponse({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.createdAt,
  });

  factory GroupPreviewResponse.fromJson(Map<String, dynamic> json) {
    return GroupPreviewResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      memberCount: json['member_count'] as int,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String name;
  final int memberCount;
  final String createdAt;
}

/// Response model for join group API.
class JoinGroupResponse {
  const JoinGroupResponse({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.role,
  });

  factory JoinGroupResponse.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>;
    return JoinGroupResponse(
      groupId: group['id'] as int,
      groupName: group['name'] as String,
      memberCount: group['member_count'] as int,
      role: group['role'] as String,
    );
  }

  final int groupId;
  final String groupName;
  final int memberCount;
  final String role;
}

/// Model for a user's group membership info.
class UserGroup {
  const UserGroup({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.role,
    required this.joinedAt,
    required this.createdAt,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      role: json['role'] as String,
      joinedAt: json['joined_at'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String name;
  final String? description;
  final int memberCount;
  final String role;
  final String joinedAt;
  final String createdAt;

  bool get isAdmin => role == 'admin';
}

/// Response model for get user groups API.
class GetUserGroupsResponse {
  const GetUserGroupsResponse({required this.groups});

  factory GetUserGroupsResponse.fromJson(Map<String, dynamic> json) {
    final groupsList = json['groups'] as List<dynamic>;
    return GetUserGroupsResponse(
      groups: groupsList
          .map((g) => UserGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<UserGroup> groups;
}

/// Model for group default settings.
class GroupSettings {
  const GroupSettings({
    required this.requireConfirmationDefault,
    required this.autoCompleteRedemptionDefault,
    required this.autoFulfillRedemptionDefault,
    required this.providerIncentiveRatio,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      requireConfirmationDefault: json['require_confirmation_default'] as bool,
      autoCompleteRedemptionDefault:
          json['auto_complete_redemption_default'] as bool,
      autoFulfillRedemptionDefault:
          json['auto_fulfill_redemption_default'] as bool,
      providerIncentiveRatio: json['provider_incentive_ratio'] as int,
    );
  }

  final bool requireConfirmationDefault;
  final bool autoCompleteRedemptionDefault;
  final bool autoFulfillRedemptionDefault;
  final int providerIncentiveRatio;
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

  /// Gets the invitation code for a group.
  /// Only admins can access this endpoint.
  Future<InvitationResponse> getInvitationCode({required int groupId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/invitation',
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return InvitationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Refreshes the invitation code for a group.
  /// Only admins can access this endpoint.
  Future<InvitationResponse> refreshInvitationCode({
    required int groupId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/$groupId/invitation/refresh',
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return InvitationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Gets group preview by invitation code.
  /// This is a public endpoint that doesn't require authentication.
  Future<GroupPreviewResponse> getGroupByInvitation({
    required String code,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/by-invitation/$code',
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return GroupPreviewResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Joins a group using an invitation code.
  Future<JoinGroupResponse> joinGroup({required String invitationCode}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/join',
        data: {'invitation_code': invitationCode},
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return JoinGroupResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Gets all groups the current user belongs to.
  Future<GetUserGroupsResponse> getUserGroups() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/groups');

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return GetUserGroupsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Lists all members of a group.
  Future<List<Map<String, dynamic>>> listMembers({required int groupId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/members',
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return (response.data!['members'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates a member's role in a group.
  Future<void> updateMemberRole({
    required int groupId,
    required int userId,
    required String role,
  }) async {
    try {
      await _dio.put<void>(
        '/v1/groups/$groupId/members/$userId/role',
        data: {'role': role},
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates a member's permissions in a group.
  Future<void> updateMemberPermissions({
    required int groupId,
    required int userId,
    required List<String> permissions,
  }) async {
    try {
      await _dio.put<void>(
        '/v1/groups/$groupId/members/$userId/permissions',
        data: {'permissions': permissions},
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Gets the default settings for a group.
  Future<GroupSettings> getGroupSettings({required int groupId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/settings',
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return GroupSettings.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates the default settings for a group.
  Future<GroupSettings> updateGroupSettings({
    required int groupId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/groups/$groupId/settings',
        data: settings,
      );

      if (response.data == null) {
        throw const GroupApiException('Unexpected null response');
      }

      return GroupSettings.fromJson(response.data!);
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
