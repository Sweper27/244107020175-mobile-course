import 'package:flutter/material.dart';

/// Announcement detail page, opened when a notification is tapped.
///
/// The [id] is passed via GoRouter path parameter from /pengumuman/:id.
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // Mock announcement data based on ID
    final announcement = _getAnnouncementById(id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman #$id'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Pengumuman #$id',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              announcement['title']!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Date
            Text(
              announcement['date']!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 16),

            // Body
            Text(
              announcement['body']!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns mock announcement data based on [id].
  Map<String, String> _getAnnouncementById(String id) {
    final announcements = {
      '1': {
        'title': 'Registrasi Semester Baru',
        'body':
            'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran dan KRS sebelum tanggal 15 Oktober.',
        'date': '1 Oktober 2026',
      },
      '2': {
        'title': 'Pemeliharaan Sistem',
        'body':
            'Sistem informasi akademik akan mengalami pemeliharaan pada hari Sabtu, 10 Oktober 2026 pukul 22.00-06.00.',
        'date': '5 Oktober 2026',
      },
      '3': {
        'title': 'Jadwal Kuliah Berubah',
        'body':
            'Kelas Mobile Programming dipindahkan ke ruang A2 pukul 13.00.',
        'date': '7 Oktober 2026',
      },
    };

    return announcements[id] ??
        {
          'title': 'Pengumuman #$id',
          'body': 'Detail pengumuman dengan ID $id.',
          'date': '-',
        };
  }
}

