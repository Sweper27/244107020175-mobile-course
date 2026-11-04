import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notification/features/announcements/domain/usecases/get_announcement_by_id.dart';
import 'package:campus_notification/features/announcements/domain/usecases/get_announcements.dart';

/// Fake repository implementing AnnouncementRepository interface.
/// Operates entirely in-memory without network or database.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({
    this.items = const [],
    this.fail = false,
    this.failureMessage = 'Network connection lost',
  });

  final List<Announcement> items;
  final bool fail;
  final String failureMessage;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    if (fail) {
      return (announcement: null, failure: NetworkFailure(failureMessage));
    }

    try {
      final item = items.firstWhere((element) => element.id == id);
      return (announcement: item, failure: null);
    } catch (_) {
      return (
        announcement: null,
        failure: NotFoundFailure('Pengumuman dengan ID $id tidak ditemukan'),
      );
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure(failureMessage),
      );
    }
    return (announcements: items, failure: null);
  }
}

void main() {
  group('GetAnnouncementById UseCase Tests', () {
    const sampleAnnouncement = Announcement(
      id: '1',
      title: 'Registrasi Semester Baru',
      body: 'Registrasi dibuka hingga 15 Oktober.',
      date: '1 Oktober 2026',
    );

    test('1. Skenario Sukses: Mengembalikan announcement yang sesuai dari fake repository', () async {
      final fakeRepo = FakeAnnouncementRepository(items: [sampleAnnouncement]);
      final useCase = GetAnnouncementById(fakeRepo);

      final result = await useCase('1');

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement!.id, '1');
      expect(result.announcement!.title, 'Registrasi Semester Baru');
      expect(result.announcement!.body, 'Registrasi dibuka hingga 15 Oktober.');
    });

    test('2. Skenario Gagal: Mengembalikan Failure yang benar tanpa membocorkan exception ke presentation', () async {
      final fakeRepo = FakeAnnouncementRepository(
        fail: true,
        failureMessage: 'Server unreachable',
      );
      final useCase = GetAnnouncementById(fakeRepo);

      final result = await useCase('1');

      expect(result.announcement, isNull);
      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure!.message, 'Server unreachable');
    });

    test(
      '3. Skenario Gagal: Validasi input kosong mengembalikan NotFoundFailure',
      () async {
        final fakeRepo = FakeAnnouncementRepository();
        final useCase = GetAnnouncementById(fakeRepo);

        final result = await useCase('   ');

        expect(result.announcement, isNull);
        expect(result.failure, isA<NotFoundFailure>());
        expect(result.failure!.message, 'ID pengumuman tidak valid');
      },
    );
  });

  group('GetAnnouncements UseCase Tests', () {
    test('4. Skenario Sukses: Mengembalikan seluruh daftar announcement dari fake repository', () async {
      final fakeRepo = FakeAnnouncementRepository(
        items: [
          const Announcement(
            id: '1',
            title: 'Pengumuman 1',
            body: 'Isi 1',
            date: '1 Okt 2026',
          ),
          const Announcement(
            id: '2',
            title: 'Pengumuman 2',
            body: 'Isi 2',
            date: '2 Okt 2026',
          ),
        ],
      );
      final useCase = GetAnnouncements(fakeRepo);

      final result = await useCase();

      expect(result.failure, isNull);
      expect(result.announcements.length, 2);
      expect(result.announcements[0].title, 'Pengumuman 1');
      expect(result.announcements[1].title, 'Pengumuman 2');
    });
  });
}
