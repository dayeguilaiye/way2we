import 'package:dio/dio.dart';
import 'package:way2we_app/features/redemption/data/models/redemption_order.dart';

/// Exception thrown when redemption API operations fail.
class RedemptionApiException implements Exception {
  const RedemptionApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'RedemptionApiException: $message (code: $code)';
}

/// Response model for listing orders.
class ListOrdersResponse {
  const ListOrdersResponse({required this.orders});

  factory ListOrdersResponse.fromJson(Map<String, dynamic> json) {
    final list = json['orders'] as List<dynamic>;
    return ListOrdersResponse(
      orders: list
          .map((item) => RedemptionOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<RedemptionOrder> orders;
}

/// Provider for redemption-related API calls.
class RedemptionProvider {
  RedemptionProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<RedemptionOrder> createRedemption({
    required int groupId,
    required int rewardId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/groups/$groupId/rewards/$rewardId/redemptions',
        data: {'quantity': quantity},
      );

      if (response.data == null) {
        throw const RedemptionApiException('Unexpected null response');
      }

      final payload = response.data!;
      final orderJson = payload['order'] is Map<String, dynamic>
          ? payload['order'] as Map<String, dynamic>
          : payload;
      return RedemptionOrder.fromJson(orderJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<List<RedemptionOrder>> listOrders({
    required int groupId,
    String? status,
    String? role,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        throw const RedemptionApiException('Unexpected null response');
      }

      return ListOrdersResponse.fromJson(response.data!).orders;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<RedemptionOrder> getOrderDetail({
    required int groupId,
    required int orderId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/groups/$groupId/orders/$orderId',
      );

      if (response.data == null) {
        throw const RedemptionApiException('Unexpected null response');
      }

      final payload = response.data!;
      final orderJson = payload['order'] is Map<String, dynamic>
          ? payload['order'] as Map<String, dynamic>
          : payload;
      return RedemptionOrder.fromJson(orderJson);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> fulfillOrder({
    required int groupId,
    required int orderId,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/orders/$orderId/fulfill',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> confirmOrder({
    required int groupId,
    required int orderId,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/orders/$orderId/confirm',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> markUnsatisfied({
    required int groupId,
    required int orderId,
    String? reason,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/groups/$groupId/orders/$orderId/unsatisfied',
        data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
      );
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      throw RedemptionApiException(
        data['message'] as String? ?? 'Unknown error',
        code: data['code'] as String?,
      );
    }
    throw RedemptionApiException(e.message ?? 'Network error');
  }
}
