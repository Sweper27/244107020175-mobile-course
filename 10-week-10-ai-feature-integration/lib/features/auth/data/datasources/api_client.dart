import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import 'token_store.dart';

/// Dio HTTP client with automatic Authorization header injection
/// and token refresh interceptor.
class ApiClient {
  ApiClient({
    required this.tokenStore,
    required this.authRepository,
    required this.onSessionExpired,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://mock-api.example.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      _AuthInterceptor(
        tokenStore: tokenStore,
        authRepository: authRepository,
        onSessionExpired: onSessionExpired,
        dio: _dio,
      ),
    );
  }

  final TokenStore tokenStore;
  final AuthRepository authRepository;
  final Future<void> Function() onSessionExpired;

  late final Dio _dio;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.tokenStore,
    required this.authRepository,
    required this.onSessionExpired,
    required this.dio,
  });

  final TokenStore tokenStore;
  final AuthRepository authRepository;
  final Future<void> Function() onSessionExpired;
  final Dio dio;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStore.readAccess();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final result = await authRepository.refreshToken();

        if (result.refreshed) {
          // Retry original request with new token
          final newAccessToken = await tokenStore.readAccess();
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final response = await dio.fetch(options);
          _isRefreshing = false;
          return handler.resolve(response);
        } else {
          _isRefreshing = false;
          developer.log(
            'Session expired, triggering logout callback',
            name: 'ApiClient',
          );
          await onSessionExpired();
          return handler.reject(err);
        }
      } catch (e) {
        _isRefreshing = false;
        developer.log('Error refreshing token: $e', name: 'ApiClient');
        await onSessionExpired();
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}
