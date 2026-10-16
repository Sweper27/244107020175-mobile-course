import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/token_store.dart';
import '../data/auth_repository.dart';
import '../data/api_client.dart';

// --- Singleton providers ---

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(tokenStore: ref.watch(tokenStoreProvider));
});

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

// --- Auth State ---

/// Represents the authentication state of the app.
enum AuthStatus { unknown, authenticated, unauthenticated }


class AuthNotifier extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    final authRepo = ref.read(authRepositoryProvider);
    final loggedIn = await authRepo.isLoggedIn();
    return loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }


  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final success = await authRepo.login(email, password);

      if (!success) {
        throw Exception('Email atau password salah');
      }

      return AuthStatus.authenticated;
    });
  }

  /// Logs the user out and clears tokens.
  Future<void> logout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    state = const AsyncData(AuthStatus.unauthenticated);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);

