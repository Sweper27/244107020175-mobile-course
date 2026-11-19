import 'dart:async';

import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/auth/presentation/pages/login_page.dart';
import 'package:campus_notification/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Widget test halaman login (JS 12).
///
/// Dependensi autentikasi diganti melalui `ProviderScope.overrides` sehingga
/// pengujian tidak membutuhkan FlutterSecureStorage asli maupun jaringan.
void main() {
  Widget buildLoginPage(FakeAuthRepository repository) {
    return ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage - tampilan awal', () {
    testWidgets('menampilkan judul, form, dan tombol login', (tester) async {
      // Arrange
      final repository = FakeAuthRepository();

      // Act
      await tester.pumpWidget(buildLoginPage(repository));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Campus Notification'), findsOneWidget);
      expect(find.text('Silakan login untuk melanjutkan'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('mahasiswa@kampus.ac.id'), findsOneWidget);
      expect(repository.loginCallCount, 0);
    });
  });

  group('LoginPage - validasi form', () {
    testWidgets('menampilkan pesan error saat email kosong', (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(buildLoginPage(repository));
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(repository.loginCallCount, 0);
    });

    testWidgets('menampilkan pesan error saat password kosong', (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(buildLoginPage(repository));
      await tester.enterText(find.byType(TextFormField).last, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
      expect(repository.loginCallCount, 0);
    });
  });

  group('LoginPage - interaksi pengguna', () {
    testWidgets('menampilkan indikator loading dan menonaktifkan tombol', (
      tester,
    ) async {
      // Arrange: login ditahan oleh Completer agar state loading terlihat.
      final gate = Completer<void>();
      final repository = FakeAuthRepository(loginGate: gate.future);

      await tester.pumpWidget(buildLoginPage(repository));
      // Tunggu pemeriksaan status autentikasi awal selesai agar tombol aktif.
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Assert: indikator tampil dan tombol tidak dapat ditekan ulang.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);

      // Act: selesaikan proses login.
      gate.complete();
      await tester.pumpAndSettle();

      // Assert: tombol kembali normal setelah loading selesai.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(repository.loginCallCount, 1);
    });

    testWidgets('menampilkan SnackBar saat kredensial salah', (tester) async {
      final repository = FakeAuthRepository(
        loginFailure: const AuthFailure('Email atau password salah'),
      );

      await tester.pumpWidget(buildLoginPage(repository));
      // Tunggu pemeriksaan status autentikasi awal selesai agar tombol aktif.
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Email atau password salah'), findsOneWidget);
      expect(repository.loginCallCount, 1);
    });
  });
}
