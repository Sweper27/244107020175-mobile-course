import 'package:campus_notification/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration test alur utama aplikasi `campus_notification` (JS 12).
///
/// Dijalankan pada perangkat/emulator dengan perintah:
///   flutter test integration_test/app_test.dart -d device_id
///
/// Alur yang diuji: login dengan kredensial demo bawaan aplikasi, pemuatan
/// daftar pengumuman, pencarian kata kunci, lalu membuka detail pengumuman.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Menunggu [finder] muncul dengan `pump()` bertahap.
  ///
  /// `pumpAndSettle()` tidak dipakai saat indikator loading berputar karena
  /// animasi tersebut terjadwal terus-menerus sehingga tidak pernah "settle".
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Elemen tidak ditemukan dalam batas waktu: $finder');
  }

  testWidgets('pengguna dapat login, mencari, dan membuka detail pengumuman', (
    tester,
  ) async {
    // Arrange: jalankan aplikasi sungguhan melalui entry point project.
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Assert: halaman login tampil sebagai halaman awal.
    await waitFor(tester, find.text('Silakan login untuk melanjutkan'));

    // Act: login memakai kredensial demo yang sudah terisi pada form.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    // Assert: pengguna masuk ke halaman utama dan daftar pengumuman tampil.
    await waitFor(tester, find.text('Selamat datang!'));
    await waitFor(tester, find.text('Daftar Pengumuman Kampus'));
    await waitFor(tester, find.text('Registrasi Semester Baru'));

    // Act: mencari pengumuman berdasarkan judul.
    await tester.enterText(find.byType(TextField), 'Registrasi');
    await tester.pump(const Duration(milliseconds: 500));

    // Assert: hanya pengumuman yang cocok yang tersisa.
    expect(find.text('Registrasi Semester Baru'), findsOneWidget);
    expect(find.text('Pemeliharaan Sistem'), findsNothing);

    // Act: membuka detail pengumuman.
    await tester.tap(find.text('Registrasi Semester Baru'));
    await tester.pump();

    // Assert: halaman detail tampil dengan judul pengumuman.
    await waitFor(tester, find.text('Pengumuman #1'));
    expect(
      find.text('Registrasi Semester Baru'),
      findsWidgets,
    );
  });
}
