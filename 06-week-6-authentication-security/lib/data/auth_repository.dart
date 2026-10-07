import 'token_store.dart';


class AuthRepository {
  AuthRepository({required this.tokenStore});

  final TokenStore tokenStore;


  static const _validEmail = 'mahasiswa@kampus.ac.id';
  static const _validPassword = '123456';

 
  int _tokenVersion = 1;

 
  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email == _validEmail && password == _validPassword) {
      _tokenVersion = 1;
      final accessToken = 'mock_access_token_v$_tokenVersion';
      final refreshToken = 'mock_refresh_token_v$_tokenVersion';

      await tokenStore.save(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Log safely — never print full tokens in production
      print('[Auth] Login successful (token version: $_tokenVersion)');

      return true;
    }

    print('[Auth] Login failed — invalid credentials');
    return false;
  }

  
  Future<bool> refresh() async {
    final refreshToken = await tokenStore.readRefresh();

    if (refreshToken == null || refreshToken.isEmpty) {
      print('[Auth] Refresh failed — no refresh token available');
      await tokenStore.clear();
      return false;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate a successful token refresh
    _tokenVersion++;
    final newAccessToken = 'mock_access_token_v$_tokenVersion';

    await tokenStore.save(
      accessToken: newAccessToken,
      refreshToken: refreshToken, // refresh token stays the same
    );

    print('[Auth] Token refreshed (version: $_tokenVersion)');
    return true;
  }

  /// Logs the user out by clearing all stored tokens.
  Future<void> logout() async {
    await tokenStore.clear();
    _tokenVersion = 1;
    print('[Auth] Logged out — tokens cleared');
  }

  /// Checks whether the user has a stored access token (i.e., is logged in).
  Future<bool> isLoggedIn() async {
    final token = await tokenStore.readAccess();
    return token != null && token.isNotEmpty;
  }
}

