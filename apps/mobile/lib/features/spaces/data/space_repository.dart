import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models.dart';

class PendingOperation {
  const PendingOperation({
    required this.key,
    required this.path,
    required this.method,
    this.data,
  });
  final String key, path, method;
  final Map<String, dynamic>? data;
  Map<String, dynamic> toJson() => {
    'key': key,
    'path': path,
    'method': method,
    'data': data,
  };
  factory PendingOperation.fromJson(Map<String, dynamic> j) => PendingOperation(
    key: j['key'] as String,
    path: j['path'] as String,
    method: j['method'] as String,
    data: j['data'] as Map<String, dynamic>?,
  );
}

abstract interface class OperationStore {
  Future<PendingOperation?> read(String userId);
  Future<void> write(String userId, PendingOperation? op);
}

class SecureOperationStore implements OperationStore {
  const SecureOperationStore(this.storage);
  final FlutterSecureStorage storage;
  String key(String uid) => 'way2we.business-intent.v1.$uid';
  @override
  Future<PendingOperation?> read(String userId) async {
    try {
      final raw = await storage.read(key: key(userId));
      return raw == null
          ? null
          : PendingOperation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> write(String userId, PendingOperation? op) async {
    try {
      if (op == null) {
        await storage.delete(key: key(userId));
      } else {
        await storage.write(key: key(userId), value: jsonEncode(op.toJson()));
      }
    } catch (_) {
      throw const StorageFailure();
    }
  }
}

class SpaceRepository {
  const SpaceRepository(this.api);
  final ApiClient api;
  Future<Map<String, dynamic>> command(PendingOperation op) => api.request(
    op.path,
    method: op.method,
    data: op.data,
    idempotencyKey: op.key,
  );
  Future<InvitePreview> preview(String code) async => InvitePreview.fromJson(
    await api.request(
      '/v1/invitations/preview',
      method: 'POST',
      data: {'invite_code': code},
    ),
  );
  Future<DataPage<SpaceInfo>> spaces(String? cursor) async => DataPage.fromJson(
    await api.request(pagePath('/v1/spaces', cursor)),
    SpaceInfo.summary,
  );
  Future<String> spaceName(String id) async {
    final j = await api.request('/v1/spaces/$id');
    return parse(() => j['name'] as String);
  }

  Future<DataPage<MemberInfo>> members(String id, String? cursor) async =>
      DataPage.fromJson(
        await api.request(pagePath('/v1/spaces/$id/members', cursor)),
        MemberInfo.fromJson,
      );
  Future<DataPage<InvitationInfo>> invitations(
    String id,
    String? cursor,
  ) async => DataPage.fromJson(
    await api.request(pagePath('/v1/spaces/$id/invitations', cursor)),
    InvitationInfo.fromJson,
  );
  Future<InvitationInfo> invitation(String id) async =>
      InvitationInfo.fromJson(await api.request('/v1/invitations/$id'));
  Future<DataPage<NoticeInfo>> notices(String? cursor) async =>
      DataPage.fromJson(
        await api.request(pagePath('/v1/notifications', cursor)),
        NoticeInfo.fromJson,
      );
}

String pagePath(String path, String? cursor) => Uri(
  path: path,
  queryParameters: {'limit': '20', 'cursor': ?cursor},
).toString();
String? invitationCode(String raw) {
  var code = raw.trim();
  final uri = Uri.tryParse(code);
  if (uri != null && uri.hasScheme) {
    code = uri.queryParameters['code'] ?? '';
  }
  code = code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^[A-Z2-7]{20}$').hasMatch(code) ? code : null;
}

String invitationLink(String code) {
  const base = String.fromEnvironment(
    'INVITE_BASE_URL',
    defaultValue: 'way2we://app/join',
  );
  final uri = Uri.parse(base);
  return uri.replace(queryParameters: {'code': code}).toString();
}
