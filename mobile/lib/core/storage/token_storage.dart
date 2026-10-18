import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<bool> hasAccessToken();
}

class PlatformTokenStorage implements TokenStorage {
  static const String _keyAccessToken = 'unicheck_access_token';
  static const String _keyRefreshToken = 'unicheck_refresh_token';

  final FlutterSecureStorage _storage;

  // In-memory cache for fast access & headless unit-test fallback
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  PlatformTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              webOptions: WebOptions(
                dbName: 'unicheck_vault',
                publicKey: 'unicheck_auth',
              ),
            );

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;

    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {
      // In-memory cache remains available
    }
  }

  @override
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    try {
      _cachedAccessToken = await _storage.read(key: _keyAccessToken);
      return _cachedAccessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    try {
      _cachedRefreshToken = await _storage.read(key: _keyRefreshToken);
      return _cachedRefreshToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;

    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    } catch (_) {
      // In-memory cleared
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
