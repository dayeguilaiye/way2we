import 'package:dio/dio.dart';
import 'package:way2we_app/features/agreement/models/agreement.dart';

/// Exception thrown when agreement API operations fail.
class AgreementApiException implements Exception {
  const AgreementApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AgreementApiException: $message (code: $code)';
}

/// Input model for creating an agreement.
class CreateAgreementInput {
  const CreateAgreementInput({
    required this.name,
    required this.points,
    this.description,
    this.requireConfirmation,
    this.coverImageUrl,
    this.applicableMemberIds,
  });

  final String name;
  final String? description;
  final int points;
  final bool? requireConfirmation;
  final String? coverImageUrl;
  final List<int>? applicableMemberIds;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'points': points,
      if (requireConfirmation != null)
        'require_confirmation': requireConfirmation,
      if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        'cover_image_url': coverImageUrl,
      if (applicableMemberIds != null && applicableMemberIds!.isNotEmpty)
        'applicable_member_ids': applicableMemberIds,
    };
  }
}

/// Input model for updating an agreement.
class UpdateAgreementInput {
  const UpdateAgreementInput({
    this.name,
    this.description,
    this.points,
    this.requireConfirmation,
    this.coverImageUrl,
    this.applicableMemberIds,
  });

  final String? name;
  final String? description;
  final int? points;
  final bool? requireConfirmation;
  final String? coverImageUrl;
  final List<int>? applicableMemberIds;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (points != null) 'points': points,
      if (requireConfirmation != null)
        'require_confirmation': requireConfirmation,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (applicableMemberIds != null)
        'applicable_member_ids': applicableMemberIds,
    };
  }
}

/// Response model for listing agreements.
class ListAgreementsResponse {
  const ListAgreementsResponse({required this.agreements});

  factory ListAgreementsResponse.fromJson(Map<String, dynamic> json) {
    final agreementsList = json['agreements'] as List<dynamic>;
    return ListAgreementsResponse(
      agreements: agreementsList
          .map((a) => Agreement.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<Agreement> agreements;
}

/// Provider for agreement-related API calls.
class AgreementProvider {
  AgreementProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Lists all agreements for a group.
  /// Optionally filter by status ('active' or 'inactive').
  Future<List<Agreement>> listAgreements({
    required int groupId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        throw const AgreementApiException('Unexpected null response');
      }

      return ListAgreementsResponse.fromJson(response.data!).agreements;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Creates a new agreement in the group.
  Future<Agreement> createAgreement({
    required int groupId,
    required CreateAgreementInput input,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements',
        data: input.toJson(),
      );

      if (response.data == null) {
        throw const AgreementApiException('Unexpected null response');
      }

      return Agreement.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Gets a single agreement by ID.
  Future<Agreement> getAgreement({
    required int groupId,
    required int agreementId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements/$agreementId',
      );

      if (response.data == null) {
        throw const AgreementApiException('Unexpected null response');
      }

      return Agreement.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates an existing agreement.
  Future<Agreement> updateAgreement({
    required int groupId,
    required int agreementId,
    required UpdateAgreementInput input,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements/$agreementId',
        data: input.toJson(),
      );

      if (response.data == null) {
        throw const AgreementApiException('Unexpected null response');
      }

      return Agreement.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Updates the status of an agreement (activate/deactivate).
  Future<Agreement> updateAgreementStatus({
    required int groupId,
    required int agreementId,
    required String status,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements/$agreementId/status',
        data: {'status': status},
      );

      if (response.data == null) {
        throw const AgreementApiException('Unexpected null response');
      }

      return Agreement.fromJson(response.data!);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Pins an agreement for the current user.
  Future<void> pinAgreement({
    required int groupId,
    required int agreementId,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/agreements/$agreementId/pin',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Unpins an agreement for the current user.
  Future<void> unpinAgreement({
    required int groupId,
    required int agreementId,
  }) async {
    try {
      await _dio.delete<void>(
        '/v1/groups/$groupId/agreements/$agreementId/pin',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw AgreementApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw AgreementApiException(e.message ?? 'Network error');
  }
}
