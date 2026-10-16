import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

 
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }


  Future<String?> readAccess() async {
    return _storage.read(key: _accessTokenKey);
  }


  Future<String?> readRefresh() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Clears all stored tokens (used during logout).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

