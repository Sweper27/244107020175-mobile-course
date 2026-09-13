import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// Menggunakan ConsumerWidget (pola modern Riverpod)
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch HANYA digunakan di dalam method build untuk me-rebuild UI saat state berubah
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Belajar'),
      ),
      // Memastikan ketiga state AsyncValue (loading, error, data/success) ditangani
      body: statsAsync.when(
        // State 1: Loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // State 2: Error (Handling pesan error + tombol retry)
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  // ref.read HANYA digunakan di dalam event callback (onPressed)
                  onPressed: () => ref.read(statsProvider.notifier).retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        // State 3: Data / Success (ListView 3 Item)
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(item.label),
              trailing: Text(
                item.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}