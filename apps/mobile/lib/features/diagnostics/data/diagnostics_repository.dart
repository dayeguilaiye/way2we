import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';

class DiagnosticsRepository {
  DiagnosticsRepository(this.api);
  final ApiClient api;
  Future<String> checkConnection() async {
    final body = await api.request('/health/ready', authenticated: false);
    if (body['status'] != 'ok') throw const ProtocolFailure();
    return '连接正常';
  }

  Future<String> validateQuantity(int quantity) async {
    final body = await api.request(
      '/dev/validate',
      method: 'POST',
      data: {'quantity': quantity},
      authenticated: false,
    );
    if (body['quantity'] != quantity) throw const ProtocolFailure();
    return '数量已验证：$quantity';
  }

  Future<String> checkGenericError() async {
    await api.request('/dev/missing', authenticated: false);
    throw const ProtocolFailure();
  }
}
