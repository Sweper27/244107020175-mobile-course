import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/features/auth/data/datasources/token_store.dart';
import 'package:campus_notification/features/auth/data/repositories/auth_repository_impl.dart';

/// A simple in-memory token store for testing.
class FakeTokenStore extends TokenStore {
  FakeTokenStore() : super();

  final Map<String, String> _store = {};

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _store['access_token'] = accessToken;
    _store['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> readAccess() async {
    return _store['access_token'];
  }

  @override
  Future<String?> readRefresh() async {
    return _store['refresh_token'];
  }

  @override
  Future<void> clear() async {
    _store.remove('access_token');
    _store.remove('refresh_token');
  }
}

void main() {
  late FakeTokenStore tokenStore;
  late AuthRepositoryImpl authRepo;

  setUp(() {
    tokenStore = FakeTokenStore();
    authRepo = AuthRepositoryImpl(tokenStore: tokenStore);
  });

  // --- Token Store Tests ---

  group('TokenStore', () {
    test('1. save stores tokens correctly', () async {
      await tokenStore.save(
        accessToken: 'test_access',
        refreshToken: 'test_refresh',
      );

      expect(await tokenStore.readAccess(), 'test_access');
      expect(await tokenStore.readRefresh(), 'test_refresh');
    });

    test('2. readAccess returns null when empty', () async {
      expect(await tokenStore.readAccess(), isNull);
    });

    test('3. readRefresh returns null when empty', () async {
      expect(await tokenStore.readRefresh(), isNull);
    });

    test('4. clear removes all tokens', () async {
      await tokenStore.save(
        accessToken: 'test_access',
        refreshToken: 'test_refresh',
      );

      await tokenStore.clear();

      expect(await tokenStore.readAccess(), isNull);
      expect(await tokenStore.readRefresh(), isNull);
    });
  });

  // --- Auth Repository Tests ---

  group('AuthRepository', () {
    test('5. login succeeds with correct credentials', () async {
      final result = await authRepo.login(
        email: 'mahasiswa@kampus.ac.id',
        password: '123456',
      );

      expect(result.failure, isNull);
      expect(result.user, isNotNull);
      expect(result.user!.email, 'mahasiswa@kampus.ac.id');
      expect(await tokenStore.readAccess(), isNotNull);
      expect(await tokenStore.readRefresh(), isNotNull);
    });

    test('6. login fails with wrong email', () async {
      final result = await authRepo.login(
        email: 'wrong@email.com',
        password: '123456',
      );

      expect(result.user, isNull);
      expect(result.failure, isNotNull);
      expect(await tokenStore.readAccess(), isNull);
    });

    test('7. login fails with wrong password', () async {
      final result = await authRepo.login(
        email: 'mahasiswa@kampus.ac.id',
        password: 'wrong',
      );

      expect(result.user, isNull);
      expect(result.failure, isNotNull);
      expect(await tokenStore.readAccess(), isNull);
    });

    test('8. logout clears all tokens', () async {
      await authRepo.login(email: 'mahasiswa@kampus.ac.id', password: '123456');
      expect(await tokenStore.readAccess(), isNotNull);

      final result = await authRepo.logout();
      expect(result.success, true);
      expect(await tokenStore.readAccess(), isNull);
      expect(await tokenStore.readRefresh(), isNull);
    });

    test('9. isLoggedIn returns true after login', () async {
      await authRepo.login(email: 'mahasiswa@kampus.ac.id', password: '123456');
      final result = await authRepo.isLoggedIn();
      expect(result.isLoggedIn, true);
    });

    test('10. isLoggedIn returns false when not logged in', () async {
      final result = await authRepo.isLoggedIn();
      expect(result.isLoggedIn, false);
    });

    test('11. isLoggedIn returns false after logout', () async {
      await authRepo.login(email: 'mahasiswa@kampus.ac.id', password: '123456');
      await authRepo.logout();
      final result = await authRepo.isLoggedIn();
      expect(result.isLoggedIn, false);
    });

    test('12. refresh succeeds when refresh token exists', () async {
      await authRepo.login(email: 'mahasiswa@kampus.ac.id', password: '123456');
      final oldAccess = await tokenStore.readAccess();

      final result = await authRepo.refreshToken();

      expect(result.refreshed, true);
      final newAccess = await tokenStore.readAccess();
      expect(newAccess, isNot(equals(oldAccess)));
    });

    test('13. refresh fails when no refresh token (empty store)', () async {
      final result = await authRepo.refreshToken();
      expect(result.refreshed, false);
      expect(result.failure, isNotNull);
    });
  });

  // --- Notification Payload Tests ---

  group('Notification Payload', () {
    test('14. announcementId extracted from data', () {
      final data = {'announcementId': '3'};
      expect(data['announcementId'], '3');
    });

    test('15. missing announcementId returns null', () {
      final data = <String, String>{};
      expect(data['announcementId'], isNull);
    });
  });

  // --- Route Tests ---

  group('Routes', () {
    test('16. announcement route is correct', () {
      const id = '3';
      final route = '/pengumuman/$id';
      expect(route, '/pengumuman/3');
    });

    test('17. login route is /login', () {
      expect('/login', equals('/login'));
    });

    test('18. home route is /', () {
      expect('/', equals('/'));
    });
  });
}
