import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:way2we_app/features/reward/data/models/reward.dart';

/// Exception thrown when reward API operations fail.
class RewardApiException implements Exception {
  const RewardApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'RewardApiException: $message (code: $code)';
}

/// Input model for creating a reward.
class CreateRewardInput {
  const CreateRewardInput({
    required this.name,
    required this.costPoints,
    this.description,
    this.autoFulfill,
    this.autoComplete,
    this.coverImageUrl,
  });

  final String name;
  final String? description;
  final int costPoints;
  final bool? autoFulfill;
  final bool? autoComplete;
  final String? coverImageUrl;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'cost_points': costPoints,
      if (autoFulfill != null) 'auto_fulfill': autoFulfill,
      if (autoComplete != null) 'auto_complete': autoComplete,
      if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        'cover_image_url': coverImageUrl,
    };
  }
}

/// Input model for updating a reward.
class UpdateRewardInput {
  const UpdateRewardInput({
    this.name,
    this.description,
    this.costPoints,
    this.autoFulfill,
    this.autoComplete,
    this.coverImageUrl,
  });

  final String? name;
  final String? description;
  final int? costPoints;
  final bool? autoFulfill;
  final bool? autoComplete;
  final String? coverImageUrl;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (costPoints != null) 'cost_points': costPoints,
      if (autoFulfill != null) 'auto_fulfill': autoFulfill,
      if (autoComplete != null) 'auto_complete': autoComplete,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
    };
  }
}

/// Response model for listing rewards.
class ListRewardsResponse {
  const ListRewardsResponse({required this.rewards});

  factory ListRewardsResponse.fromJson(Map<String, dynamic> json) {
    final rewardsList = json['rewards'] as List<dynamic>;
    return ListRewardsResponse(
      rewards: rewardsList
          .map((r) => Reward.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<Reward> rewards;
}

/// Provider for reward-related API calls.
class RewardProvider {
  RewardProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Lists rewards for a group.
  /// Optionally filter by status ('active' or 'inactive').
  Future<List<Reward>> listRewards({
    required int groupId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/rewards',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        throw const RewardApiException('Unexpected null response');
      }

      return ListRewardsResponse.fromJson(response.data!).rewards;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Creates a new reward in the group.
  Future<Reward> createReward({
    required int groupId,
    required CreateRewardInput input,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/$groupId/rewards',
        data: input.toJson(),
      );

      if (response.data == null) {
        throw const RewardApiException('Unexpected null response');
      }

      return Reward.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates an existing reward.
  Future<Reward> updateReward({
    required int groupId,
    required int rewardId,
    required UpdateRewardInput input,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/groups/$groupId/rewards/$rewardId',
        data: input.toJson(),
      );

      if (response.data == null) {
        throw const RewardApiException('Unexpected null response');
      }

      return Reward.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates the status of a reward (activate/deactivate).
  Future<Reward> updateRewardStatus({
    required int groupId,
    required int rewardId,
    required String status,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/groups/$groupId/rewards/$rewardId/status',
        data: {'status': status},
      );

      if (response.data == null) {
        throw const RewardApiException('Unexpected null response');
      }

      return Reward.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Uploads a reward cover image and returns the URL.
  Future<String> uploadRewardCover(XFile imageFile) async {
    try {
      final mimeType = imageFile.mimeType;
      final multipart = MultipartFile.fromBytes(
        await imageFile.readAsBytes(),
        filename: imageFile.name,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      final formData = FormData.fromMap({
        'cover': multipart,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/uploads/reward-cover',
        data: formData,
      );

      if (response.data == null) {
        throw const RewardApiException('Unexpected null response');
      }

      return response.data!['url'] as String;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw RewardApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw RewardApiException(e.message ?? 'Network error');
  }
}
