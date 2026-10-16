import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/announcement_page.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final status = authState.valueOrNull;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      // While loading, don't redirect
      if (isLoading || status == null || status == AuthStatus.unknown) {
        return null;
      }

      final isLoggedIn = status == AuthStatus.authenticated;
      final isOnLogin = currentPath == '/login';

      // Not logged in and not on login page → redirect to login
      if (!isLoggedIn && !isOnLogin) {
        return '/login';
      }

      // Logged in and on login page → redirect to home
      if (isLoggedIn && isOnLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});

/// A ChangeNotifier that rebuilds when the auth state changes,
/// triggering GoRouter's redirect logic.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}
