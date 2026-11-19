import 'dart:async';

import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notification/features/auth/presentation/pages/home_page.dart';
import 'package:campus_notification/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Widget test halaman utama (JS 12).
///
/// Fokus: state loading, error, data kosong, penampilan daftar pengumuman,
/// pembaruan tampilan saat pencarian, serta aksi logout.
void main() {
  const sampleAnnouncements = [
    Announcement(
      id: '1',
      title: 'Registrasi Semester Baru',
      body: 'Registrasi dibuka hingga 15 Oktober.',
      date: '1 Oktober 2026',
    ),
    Announcement(
      id: '2',
      title: 'Pemeliharaan Sistem',
      body: 'Pemeliharaan sistem pada hari Sabtu.',
      date: '5 Oktober 2026',
    ),
  ];

  Widget buildHomePage({
    List<Override> overrides = const [],
    FakeAuthRepository? authRepository,
  }) {
    return ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
        ...overrides,
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  group('HomePage - state data', () {
    testWidgets('menampilkan indikator loading saat data dimuat', (
      tester,
    ) async {
      // Arrange
      final completer = Completer<List<Announcement>>();
      await tester.pumpWidget(
        buildHomePage(
          overrides: [
            announcementsListProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup
      completer.complete(const <Announcement>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('menampilkan pesan error saat pemuatan gagal', (tester) async {
      await tester.pumpWidget(
        buildHomePage(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future<List<Announcement>>.error(
                Exception('Gagal memuat pengumuman'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Gagal memuat pengumuman'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan state kosong saat tidak ada pengumuman', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHomePage(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(const <Announcement>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada pengumuman.'), findsOneWidget);
    });

    testWidgets('menampilkan seluruh kartu pengumuman', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildHomePage(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(sampleAnnouncements),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selamat datang!'), findsOneWidget);
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('Pemeliharaan Sistem'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });

  group('HomePage - interaksi pengguna', () {
    testWidgets('menyaring pengumuman saat pengguna mengetik kata kunci', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildHomePage(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(sampleAnnouncements),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Act: cari kata kunci yang cocok dengan satu pengumuman.
      await tester.enterText(find.byType(TextField), 'Pemeliharaan');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pemeliharaan Sistem'), findsOneWidget);
      expect(find.text('Registrasi Semester Baru'), findsNothing);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Act: cari kata kunci yang tidak ada.
      await tester.enterText(find.byType(TextField), 'KataKunciTidakAda');
      await tester.pumpAndSettle();

      // Assert: empty state informatif tampil.
      expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);

      // Act: reset pencarian melalui tombol pada empty state.
      final resetButton = find.text('Reset Pencarian');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Assert: seluruh data kembali tampil.
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('Pemeliharaan Sistem'), findsOneWidget);
    });

    testWidgets('memanggil logout saat tombol logout ditekan', (tester) async {
      // Arrange
      final authRepository = FakeAuthRepository(initialLoggedIn: true);

      await tester.pumpWidget(
        buildHomePage(
          authRepository: authRepository,
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(sampleAnnouncements),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('Logout').first);
      await tester.pumpAndSettle();

      // Assert
      expect(authRepository.logoutCallCount, 1);
    });
  });
}
