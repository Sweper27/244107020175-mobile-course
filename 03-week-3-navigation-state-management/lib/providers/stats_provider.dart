import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model immutability sederhana untuk data statistik
class StatItem {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});
}

// Notifier menggunakan AsyncNotifier untuk menangani state asinkron
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  @override
  Future<List<StatItem>> build() async {
    return _fetchStats();
  }

  // Fungsi privat untuk simulasi panggil API (delay 2 detik, 30% potensi gagal)
  Future<List<StatItem>> _fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi random error 30%
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik dari server.');
    }

    // Mengembalikan data baru (immutable list)
    return const [
      StatItem(label: 'Total Tugas Selesai', value: '24'),
      StatItem(label: 'Persentase Kelulusan', value: '95%'),
      StatItem(label: 'Total Jam Belajar', value: '48 Jam'),
    ];
  }

  // Fungsi retry untuk memuat ulang data jika terjadi error
  Future<void> retry() async {
    // Mengubah state menjadi loading secara efisien
    state = const AsyncLoading();
    // AsyncValue.guard secara otomatis menangkap exception dan mengubahnya ke AsyncError
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

// Deklarasi provider eksplisit tanpa duplikasi
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);