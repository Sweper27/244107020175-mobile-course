import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Concrete implementation of AnnouncementRepository.
/// Encapsulates local or remote data source for announcements.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl();

  static final Map<String, Map<String, String>> _storage = {
    '1': {
      'title': 'Registrasi Semester Baru',
      'body': 'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran dan KRS sebelum tanggal 15 Oktober.',
      'date': '1 Oktober 2026',
    },
    '2': {
      'title': 'Pemeliharaan Sistem',
      'body': 'Sistem informasi akademik akan mengalami pemeliharaan pada hari Sabtu, 10 Oktober 2026 pukul 22.00-06.00.',
      'date': '5 Oktober 2026',
    },
    '3': {
      'title': 'Jadwal Kuliah Berubah',
      'body': 'Kelas Mobile Programming dipindahkan ke ruang A2 pukul 13.00.',
      'date': '7 Oktober 2026',
    },
  };

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    try {
      // Simulate quick data fetch
      await Future.delayed(const Duration(milliseconds: 150));

      final data = _storage[id];
      if (data != null) {
        final model = AnnouncementModel.fromMap(data, defaultId: id);
        return (announcement: model.toEntity(), failure: null);
      }

      // Fallback for any unknown ID matching the original behavior
      final fallback = AnnouncementModel(
        id: id,
        title: 'Pengumuman #$id',
        body: 'Detail pengumuman dengan ID $id.',
        date: '-',
      );

      return (announcement: fallback.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final list = _storage.entries.map((entry) {
        return AnnouncementModel.fromMap(
          entry.value,
          defaultId: entry.key,
        ).toEntity();
      }).toList();

      return (announcements: list, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat daftar pengumuman: $e'),
      );
    }
  }
}
