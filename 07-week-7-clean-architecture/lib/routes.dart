import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/format.dart';
import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

/// App router provider using GoRouter.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final status = authState.valueOrNull;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      // While loading initial auth state, don't redirect
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
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final rawId = state.pathParameters['id'];
          final id = parseAnnouncementId(rawId);
          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});

/// A ChangeNotifier that triggers GoRouter redirect when auth state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}
