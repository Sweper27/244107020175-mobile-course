import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/domain/usecases/search_announcements.dart';
import 'package:campus_notification/features/announcements/presentation/providers/announcement_providers.dart';

void main() {
  const sampleAnnouncements = [
    Announcement(
      id: '1',
      title: 'Registrasi Semester Baru',
      body: 'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran dan KRS sebelum tanggal 15 Oktober.',
      date: '1 Oktober 2026',
    ),
    Announcement(
      id: '2',
      title: 'Pemeliharaan Sistem',
      body: 'Sistem informasi akademik akan mengalami pemeliharaan pada hari Sabtu, 10 Oktober 2026 pukul 22.00-06.00.',
      date: '5 Oktober 2026',
    ),
    Announcement(
      id: '3',
      title: 'Jadwal Kuliah Berubah',
      body: 'Kelas Mobile Programming dipindahkan ke ruang A2 pukul 13.00.',
      date: '7 Oktober 2026',
    ),
  ];

  group('SearchAnnouncements UseCase Tests', () {
    const useCase = SearchAnnouncements();

    test('1. Mengembalikan semua pengumuman ketika query kosong', () {
      final result = useCase(announcements: sampleAnnouncements, query: '');

      expect(result.length, 3);
      expect(result, equals(sampleAnnouncements));
    });

    test('2. Mengembalikan semua pengumuman ketika query hanya spasi', () {
      final result = useCase(announcements: sampleAnnouncements, query: '    ');

      expect(result.length, 3);
      expect(result, equals(sampleAnnouncements));
    });

    test(
      '3. Mencari pengumuman berdasarkan kecocokan judul (case-insensitive)',
      () {
        final result = useCase(
          announcements: sampleAnnouncements,
          query: 'registrasi',
        );

        expect(result.length, 1);
        expect(result.first.id, '1');
        expect(result.first.title, 'Registrasi Semester Baru');
      },
    );

    test('4. Mencari pengumuman berdasarkan huruf besar (uppercase query)', () {
      final result = useCase(
        announcements: sampleAnnouncements,
        query: 'SISTEM',
      );

      expect(result.length, 1);
      expect(result.first.id, '2');
      expect(result.first.title, 'Pemeliharaan Sistem');
    });

    test('5. Mencari pengumuman berdasarkan kata dalam isi (body)', () {
      final result = useCase(
        announcements: sampleAnnouncements,
        query: 'Mobile Programming',
      );

      expect(result.length, 1);
      expect(result.first.id, '3');
      expect(result.first.title, 'Jadwal Kuliah Berubah');
    });

    test('6. Mengabaikan spasi di awal dan akhir kata kunci (trimming)', () {
      final result = useCase(
        announcements: sampleAnnouncements,
        query: '   Kuliah   ',
      );

      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('7. Mengembalikan list kosong jika tidak ada yang cocok', () {
      final result = useCase(
        announcements: sampleAnnouncements,
        query: 'KataKunciYangPastiTidakAda123',
      );

      expect(result, isEmpty);
    });

    test('8. Menangani list pengumuman kosong tanpa exception', () {
      final result = useCase(announcements: const [], query: 'apapun');

      expect(result, isEmpty);
    });
  });

  group('Announcement Search Riverpod Providers Tests', () {
    test(
      '1. announcementSearchQueryProvider nilai awal berupa string kosong',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initialQuery = container.read(announcementSearchQueryProvider);
        expect(initialQuery, '');
      },
    );

    test('2. announcementSearchQueryProvider dapat diperbarui', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(announcementSearchQueryProvider.notifier).state = 'ujian';
      expect(container.read(announcementSearchQueryProvider), 'ujian');
    });

    test(
      '3. filteredAnnouncementsProvider menyaring data pengumuman',
      () async {
        final container = ProviderContainer(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(sampleAnnouncements),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Awalnya query kosong -> semua 3 pengumuman muncul
        final initialFiltered = await container.read(
          announcementsListProvider.future,
        );
        expect(initialFiltered.length, 3);

        final filteredData1 = container.read(filteredAnnouncementsProvider);
        expect(filteredData1.asData?.value.length, 3);

        // Ubah query menjadi 'Pemeliharaan'
        container.read(announcementSearchQueryProvider.notifier).state =
            'Pemeliharaan';

        final filteredData2 = container.read(filteredAnnouncementsProvider);
        expect(filteredData2.asData?.value.length, 1);
        expect(filteredData2.asData?.value.first.id, '2');

        // Ubah query menjadi kata yang tidak ada
        container.read(announcementSearchQueryProvider.notifier).state =
            'xyz999';

        final filteredData3 = container.read(filteredAnnouncementsProvider);
        expect(filteredData3.asData?.value.length, 0);
      },
    );
  });
}
