import 'package:dio/dio.dart';
import 'package:way2we_app/features/agreement/completion/models/agreement_completion.dart';

/// Exception thrown when agreement completion API operations fail.
class AgreementCompletionApiException implements Exception {
  const AgreementCompletionApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      'AgreementCompletionApiException: $message (code: $code)';
}

/// Provider for agreement completion-related API calls.
class AgreementCompletionProvider {
  AgreementCompletionProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Creates a completion record for an agreement.
  Future<AgreementCompletion> createAgreementCompletion({
    required int groupId,
    required int agreementId,
    int? completerId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreements/$agreementId/completions',
        data: completerId != null ? {'completer_id': completerId} : null,
      );

      if (response.data == null) {
        throw const AgreementCompletionApiException('Unexpected null response');
      }

      final completionJson =
          response.data!['completion'] as Map<String, dynamic>;
      return AgreementCompletion.fromJson(completionJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Lists pending completions for a group.
  Future<List<AgreementCompletion>> listPendingCompletions({
    required int groupId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{'status': 'pending'};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/agreement-completions',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw const AgreementCompletionApiException('Unexpected null response');
      }

      final list = response.data!['completions'] as List<dynamic>;
      return list
          .map(
            (item) =>
                AgreementCompletion.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Confirms a pending completion.
  Future<void> confirmCompletion({
    required int groupId,
    required int completionId,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/agreement-completions/$completionId/confirm',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Rejects a pending completion.
  Future<void> rejectCompletion({
    required int groupId,
    required int completionId,
    String? reason,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/agreement-completions/$completionId/reject',
        data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw AgreementCompletionApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw AgreementCompletionApiException(e.message ?? 'Network error');
  }
}
