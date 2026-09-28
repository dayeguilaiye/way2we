import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/session/session.dart';

class AccountUser {
  const AccountUser({
    required this.id,
    required this.name,
    required this.theme,
  });
  final String id, name;
  final AppTheme theme;
  factory AccountUser.parse(Map<String, dynamic> data) {
    if (data
        case {
          'id': final String id,
          'display_name': final String name,
          'theme': final String theme,
          'created_at': final String created,
        }
        when id.isNotEmpty &&
            name.isNotEmpty &&
            DateTime.tryParse(created) != null) {
      return AccountUser(
        id: id,
        name: name,
        theme:
            AppTheme.values.where((value) => value.name == theme).firstOrNull ??
            AppTheme.apricot,
      );
    }
    throw const ProtocolFailure();
  }
}

class LoginResult {
  const LoginResult(this.session, this.user);
  final Session session;
  final AccountUser user;
}

class ProfileIntent {
  const ProfileIntent(this.key, this.change);
  final String key;
  final Map<String, String> change;
}

abstract interface class IntentStore {
  Future<ProfileIntent?> read(String userId);
  Future<void> write(String userId, ProfileIntent? value);
}

class SecureIntentStore implements IntentStore {
  const SecureIntentStore(this.storage);
  final FlutterSecureStorage storage;
  String _key(String id) => 'way2we.profile-intent.v1.$id';
  @override
  Future<ProfileIntent?> read(String userId) async {
    try {
      final raw = await storage.read(key: _key(userId));
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileIntent(
        data['key'] as String,
        Map<String, String>.from(data['change'] as Map),
      );
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> write(String userId, ProfileIntent? value) async {
    try {
      if (value == null) {
        await storage.delete(key: _key(userId));
      } else {
        await storage.write(
          key: _key(userId),
          value: jsonEncode({'key': value.key, 'change': value.change}),
        );
      }
    } catch (_) {
      throw const StorageFailure();
    }
  }
}

String operationKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class AccountRepository {
  const AccountRepository(this.api);
  final ApiClient api;
  Future<int> sendCode(String email) async {
    final data = await api.request(
      '/v1/auth/email-codes',
      method: 'POST',
      authenticated: false,
      data: {'email': email},
    );
    if (data
        case {
          'resend_after_seconds': final int seconds,
          'expires_in_seconds': final int expires,
        }
        when seconds > 0 && expires > 0) {
      return seconds;
    }
    throw const ProtocolFailure();
  }

  Future<LoginResult> login(String email, String code) async {
    final data = await api.request(
      '/v1/auth/sessions',
      method: 'POST',
      authenticated: false,
      data: {'email': email, 'code': code},
    );
    if (data
        case {
          'access_token': final String token,
          'token_type': 'Bearer',
          'expires_at': final String expires,
          'user': final Map<String, dynamic> userData,
        }
        when token.isNotEmpty && DateTime.tryParse(expires) != null) {
      final user = AccountUser.parse(userData);
      return LoginResult(Session(userId: user.id, token: token), user);
    }
    throw const ProtocolFailure();
  }

  Future<AccountUser> me() async =>
      AccountUser.parse(await api.request('/v1/me'));
  Future<AccountUser> update(ProfileIntent intent) async => AccountUser.parse(
    await api.request(
      '/v1/me',
      method: 'PATCH',
      data: intent.change,
      idempotencyKey: intent.key,
    ),
  );
  Future<void> logout() async {
    await api.request('/v1/auth/session', method: 'DELETE');
  }
}
