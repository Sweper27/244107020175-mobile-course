import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_navigation/providers/stats_provider.dart'; 

void main() {
  group('StatsNotifier Unit Test', () {
    test('State awal harus berupa AsyncLoading lalu berubah sesuai hasil fetch', () async {
      // Membuat ProviderContainer untuk mengisolasi state saat pengujian
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Memastikan state awal saat pertama kali dibaca adalah AsyncLoading
      expect(
        container.read(statsProvider),
        isA<AsyncLoading<List<StatItem>>>(),
      );

      // Menunggu hingga proses build() selesai (delay 2 detik selesai)
      final result = await container.read(statsProvider.future);

      // Jika berhasil (70% kans sukses), pastikan data berisi 3 item statistik
      expect(result.length, equals(3));
      expect(result.first.label, equals('Total Tugas Selesai'));
    });
  });
}