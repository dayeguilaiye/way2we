import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/session/session.dart';

final sessionProvider = Provider<SessionController>((ref) {
  final session = SessionController(
    const SecureSessionStore(FlutterSecureStorage()),
  );
  ref.onDispose(session.dispose);
  return session;
});
final apiProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  final dio = createDio(baseUrl);
  ref.onDispose(() => dio.close(force: true));
  return ApiClient(dio, ref.watch(sessionProvider));
});

final bootstrapProvider = FutureProvider<void>(
  (ref) => ref.read(sessionProvider).restore(),
);
