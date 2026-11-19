import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Unit test aturan bisnis login (JS 12).
///
/// Fokus pengujian berada pada [LoginUseCase] sebagai lapisan domain:
/// validasi input, pemangkasan spasi, dan penerusan hasil repository.
void main() {
  group('LoginUseCase - validasi input', () {
    test('menolak email kosong tanpa memanggil repository', () async {
      // Arrange
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      // Act
      final result = await useCase(email: '', password: '123456');

      // Assert
      expect(result.user, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Email dan password tidak boleh kosong');
      expect(repository.loginCallCount, 0);
    });

    test('menolak email yang hanya berisi spasi', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(email: '   ', password: '123456');

      expect(result.failure, isA<AuthFailure>());
      expect(repository.loginCallCount, 0);
    });

    test('menolak password kosong', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'mahasiswa@kampus.ac.id',
        password: '',
      );

      expect(result.failure, isA<AuthFailure>());
      expect(repository.loginCallCount, 0);
    });
  });

  group('LoginUseCase - penerusan ke repository', () {
    test('memangkas spasi email dan password sebelum dikirim', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      await useCase(
        email: '  mahasiswa@kampus.ac.id  ',
        password: '  123456  ',
      );

      expect(repository.loginCallCount, 1);
      expect(repository.lastEmail, 'mahasiswa@kampus.ac.id');
      expect(repository.lastPassword, '123456');
    });

    test('mengembalikan user beserta access token saat login berhasil', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'mahasiswa@kampus.ac.id',
        password: '123456',
      );

      expect(result.failure, isNull);
      expect(result.user, isNotNull);
      expect(result.user!.email, 'mahasiswa@kampus.ac.id');
      expect(result.user!.accessToken, 'fake_access_token');
    });

    test('meneruskan kegagalan repository tanpa mengubah pesannya', () async {
      final repository = FakeAuthRepository(
        loginFailure: const AuthFailure('Email atau password salah'),
      );
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'salah@kampus.ac.id',
        password: 'salah',
      );

      expect(result.user, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Email atau password salah');
    });
  });
}
