import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repository for accessing the current user's identity.
///
/// Uses the auth token as the single persisted source of truth and caches
/// the decoded user id in memory for fast access.
class CurrentUserRepository {
  CurrentUserRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  String? _cachedToken;
  int? _cachedUserId;

  /// Returns the current user id if available; otherwise null.
  Future<int?> getUserId() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == _cachedToken && _cachedUserId != null) {
      return _cachedUserId;
    }

    final userId = _decodeUserIdFromToken(token);
    _cachedToken = token;
    _cachedUserId = userId;
    return userId;
  }

  /// Overrides the in-memory cache (useful after login).
  // ignore: use_setters_to_change_properties
  void setCachedUserId(int? userId) {
    _cachedUserId = userId;
  }

  /// Clears the in-memory cache.
  void clearCache() {
    _cachedToken = null;
    _cachedUserId = null;
  }

  int? _decodeUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return data['user_id'] as int?;
    } on Object catch (_) {
      return null;
    }
  }
}
