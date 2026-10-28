import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/api_client.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

// --- Dependency Injection via Riverpod ---

/// Provides the secure token store (Data layer).
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

/// Provides the AuthRepository abstraction (Domain contract bound to Data implementation).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  return AuthRepositoryImpl(tokenStore: tokenStore);
});

/// Provides LoginUseCase (Domain layer).
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

/// Provides LogoutUseCase (Domain layer).
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

/// Provides CheckAuthStatusUseCase (Domain layer).
final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  return CheckAuthStatusUseCase(ref.watch(authRepositoryProvider));
});

/// Provides ApiClient for authenticated network calls.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final authNotifier = ref.read(authProvider.notifier);

  return ApiClient(
    tokenStore: tokenStore,
    authRepository: authRepo,
    onSessionExpired: () async {
      await authNotifier.logout();
    },
  );
});

// --- Presentation Auth State ---

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    final checkAuth = ref.watch(checkAuthStatusUseCaseProvider);
    final result = await checkAuth();

    if (result.failure != null) {
      return AuthStatus.unauthenticated;
    }

    return result.isLoggedIn
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final loginUseCase = ref.read(loginUseCaseProvider);
      final result = await loginUseCase(email: email, password: password);

      if (result.failure != null) {
        throw Exception(result.failure!.message);
      }

      return AuthStatus.authenticated;
    });
  }

  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();
    state = const AsyncData(AuthStatus.unauthenticated);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);
