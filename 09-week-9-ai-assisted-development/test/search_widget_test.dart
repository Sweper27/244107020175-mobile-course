import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notification/features/auth/presentation/pages/home_page.dart';

void main() {
  const sampleAnnouncements = [
    Announcement(
      id: '1',
      title: 'Registrasi Semester Baru',
      body: 'Registrasi semester baru telah dibuka.',
      date: '1 Oktober 2026',
    ),
    Announcement(
      id: '2',
      title: 'Pemeliharaan Sistem',
      body: 'Sistem informasi akademik akan mengalami pemeliharaan.',
      date: '5 Oktober 2026',
    ),
    Announcement(
      id: '3',
      title: 'Jadwal Kuliah Berubah',
      body: 'Kelas Mobile Programming dipindahkan ke ruang A2.',
      date: '7 Oktober 2026',
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        announcementsListProvider.overrideWith(
          (ref) => Future.value(sampleAnnouncements),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  testWidgets(
    'HomePage Search Widget Test: filter dan informative empty state',
    (tester) async {
      // Atur ukuran layar tester agar seluruh komponen terlihat
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Pastikan input search field dan ketiga pengumuman muncul
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('Pemeliharaan Sistem'), findsOneWidget);
      expect(find.text('Jadwal Kuliah Berubah'), findsOneWidget);

      // Ketikkan kata kunci pencarian yang cocok dengan 1 pengumuman
      await tester.enterText(find.byType(TextField), 'Registrasi');
      await tester.pumpAndSettle();

      // Hanya pengumuman yang cocok yang tampil
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('Pemeliharaan Sistem'), findsNothing);
      expect(find.text('Jadwal Kuliah Berubah'), findsNothing);

      // Ketikkan kata kunci yang tidak ada sama sekali
      await tester.enterText(find.byType(TextField), 'TidakAdaDiDaftar');
      await tester.pumpAndSettle();

      // Harus menampilkan Informative Empty State
      expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada pengumuman yang cocok dengan kata kunci "TidakAdaDiDaftar".',
        ),
        findsOneWidget,
      );
      final resetButton = find.text('Reset Pencarian');
      expect(resetButton, findsOneWidget);

      // Pastikan tombol terlihat dan tekan tombol Reset Pencarian
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Seluruh pengumuman harus kembali ditampilkan
      expect(find.text('Registrasi Semester Baru'), findsOneWidget);
      expect(find.text('Pemeliharaan Sistem'), findsOneWidget);
      expect(find.text('Jadwal Kuliah Berubah'), findsOneWidget);
    },
  );
}
