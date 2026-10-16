import 'dart:developer' as developer;

import '../../../../core/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';
import '../models/auth_user_model.dart';

/// Implementation of AuthRepository in the Data layer.
/// Fulfills the domain contract using TokenStore and simulates authentication.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.tokenStore});

  final TokenStore tokenStore;

  static const _validEmail = 'mahasiswa@kampus.ac.id';
  static const _validPassword = '123456';

  int _tokenVersion = 1;

  @override
  Future<({AuthUser? user, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network latency
      await Future.delayed(const Duration(milliseconds: 600));

      if (email == _validEmail && password == _validPassword) {
        _tokenVersion = 1;
        final accessToken = 'mock_access_token_v$_tokenVersion';
        final refreshToken = 'mock_refresh_token_v$_tokenVersion';

        await tokenStore.save(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        developer.log('Login successful for $email', name: 'Auth');

        final userModel = AuthUserModel(email: email, accessToken: accessToken);

        return (user: userModel.toEntity(), failure: null);
      }

      developer.log('Login failed: invalid credentials', name: 'Auth');
      return (
        user: null,
        failure: const AuthFailure('Email atau password salah'),
      );
    } catch (e) {
      return (
        user: null,
        failure: LocalFailure('Terjadi kesalahan penyimpanan: $e'),
      );
    }
  }

  @override
  Future<({bool refreshed, Failure? failure})> refreshToken() async {
    try {
      final refreshToken = await tokenStore.readRefresh();

      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log('Refresh failed: no refresh token', name: 'Auth');
        await tokenStore.clear();
        return (
          refreshed: false,
          failure: const AuthFailure('Sesi telah kedaluwarsa'),
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));
      _tokenVersion++;
      final newAccessToken = 'mock_access_token_v$_tokenVersion';

      await tokenStore.save(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      developer.log('Token refreshed to v$_tokenVersion', name: 'Auth');
      return (refreshed: true, failure: null);
    } catch (e) {
      return (
        refreshed: false,
        failure: LocalFailure('Gagal merefresh token: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    try {
      await tokenStore.clear();
      _tokenVersion = 1;
      developer.log('User logged out, tokens cleared', name: 'Auth');
      return (success: true, failure: null);
    } catch (e) {
      return (success: false, failure: LocalFailure('Gagal logout: $e'));
    }
  }

  @override
  Future<({bool isLoggedIn, Failure? failure})> isLoggedIn() async {
    try {
      final token = await tokenStore.readAccess();
      final hasToken = token != null && token.isNotEmpty;
      return (isLoggedIn: hasToken, failure: null);
    } catch (e) {
      return (
        isLoggedIn: false,
        failure: LocalFailure('Gagal memeriksa status login: $e'),
      );
    }
  }
}
