import 'dart:async';

import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/presentation/pages/announcement_page.dart';
import 'package:campus_notification/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget test halaman detail pengumuman (JS 12).
void main() {
  const sampleAnnouncement = Announcement(
    id: '1',
    title: 'Registrasi Semester Baru',
    body: 'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran.',
    date: '1 Oktober 2026',
  );

  Widget buildPage({
    required Future<Announcement> Function(Ref ref, String id) create,
  }) {
    return ProviderScope(
      overrides: [
        announcementDetailProvider.overrideWith(create),
      ],
      child: const MaterialApp(home: AnnouncementPage(id: '1')),
    );
  }

  group('AnnouncementPage', () {
    testWidgets('menampilkan indikator loading saat detail dimuat', (
      tester,
    ) async {
      // Arrange
      final completer = Completer<Announcement>();

      await tester.pumpWidget(
        buildPage(create: (ref, id) => completer.future),
      );
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup
      completer.complete(sampleAnnouncement);
      await tester.pumpAndSettle();
    });

    testWidgets('menampilkan pesan error dan tombol coba lagi', (tester) async {
      await tester.pumpWidget(
        buildPage(
          create: (ref, id) => Future<Announcement>.error(
            Exception('Gagal memuat detail pengumuman'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat detail pengumuman'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Aksi coba lagi tidak boleh membuat halaman crash.
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('menampilkan judul, tanggal, dan isi pengumuman', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPage(create: (ref, id) => Future.value(sampleAnnouncement)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman #1'), findsNWidgets(2)); // AppBar + chip
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('1 Oktober 2026'), findsOneWidget);
      expect(
        find.text(
          'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran.',
        ),
        findsOneWidget,
      );
    });
  });
}
