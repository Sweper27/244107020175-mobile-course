import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/announcements/data/models/announcement_model.dart';
import 'package:campus_notification/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/domain/usecases/get_announcement_by_id.dart';
import 'package:campus_notification/features/announcements/domain/usecases/get_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

/// Unit test lapisan data & domain pengumuman (JS 12).
///
/// Menguji dua hal: perilaku [AnnouncementRepositoryImpl] yang dipakai
/// aplikasi (termasuk cache Stale-While-Revalidate) dan perilaku use case
/// ketika repository diganti dengan [FakeAnnouncementRepository].
void main() {
  const sampleItems = [
    Announcement(
      id: '1',
      title: 'Registrasi Semester Baru',
      body: 'Registrasi dibuka hingga 15 Oktober.',
      date: '1 Oktober 2026',
    ),
    Announcement(
      id: '2',
      title: 'Pemeliharaan Sistem',
      body: 'Pemeliharaan sistem pada hari Sabtu.',
      date: '5 Oktober 2026',
    ),
  ];

  group('GetAnnouncements - fake repository', () {
    test('mengembalikan seluruh data dari fake repository', () async {
      // Arrange
      final repository = FakeAnnouncementRepository(items: sampleItems);
      final useCase = GetAnnouncements(repository);

      // Act
      final result = await useCase();

      // Assert
      expect(result.failure, isNull);
      expect(result.announcements.length, 2);
      expect(result.announcements.first.title, 'Registrasi Semester Baru');
      expect(repository.getListCallCount, 1);
    });

    test('mengembalikan daftar kosong tanpa failure saat data kosong', () async {
      final repository = FakeAnnouncementRepository();
      final useCase = GetAnnouncements(repository);

      final result = await useCase();

      expect(result.failure, isNull);
      expect(result.announcements, isEmpty);
    });

    test('mengembalikan NetworkFailure saat repository gagal', () async {
      final repository = FakeAnnouncementRepository(
        failure: const NetworkFailure('Tidak ada koneksi internet'),
      );
      final useCase = GetAnnouncements(repository);

      final result = await useCase();

      expect(result.announcements, isEmpty);
      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure!.message, 'Tidak ada koneksi internet');
    });

    test('meneruskan exception repository apa adanya (kontrak tidak menelan error)', () async {
      final repository = FakeAnnouncementRepository(throwException: true);
      final useCase = GetAnnouncements(repository);

      await expectLater(useCase(), throwsA(isA<Exception>()));
    });
  });

  group('GetAnnouncementById - fake repository', () {
    test('mengembalikan pengumuman sesuai ID', () async {
      final repository = FakeAnnouncementRepository(items: sampleItems);
      final useCase = GetAnnouncementById(repository);

      final result = await useCase('2');

      expect(result.failure, isNull);
      expect(result.announcement?.title, 'Pemeliharaan Sistem');
      expect(repository.lastRequestedId, '2');
    });

    test('mengembalikan NotFoundFailure saat ID tidak ditemukan', () async {
      final repository = FakeAnnouncementRepository(items: sampleItems);
      final useCase = GetAnnouncementById(repository);

      final result = await useCase('99');

      expect(result.announcement, isNull);
      expect(result.failure, isA<NotFoundFailure>());
    });

    test('tidak memanggil repository ketika ID hanya berisi spasi', () async {
      final repository = FakeAnnouncementRepository(items: sampleItems);
      final useCase = GetAnnouncementById(repository);

      final result = await useCase('   ');

      expect(result.failure, isA<NotFoundFailure>());
      expect(repository.getByIdCallCount, 0);
    });
  });

  group('AnnouncementRepositoryImpl (implementasi nyata aplikasi)', () {
    test('mengembalikan daftar pengumuman pada pengambilan pertama', () async {
      final repository = AnnouncementRepositoryImpl()..clearCache();

      final result = await repository.getAnnouncements();

      expect(result.failure, isNull);
      expect(result.announcements, isNotEmpty);
      expect(result.announcements.every((item) => item.id.isNotEmpty), isTrue);
    });

    test('cache tetap menghasilkan data yang sama setelah clearCache', () async {
      final repository = AnnouncementRepositoryImpl()..clearCache();

      final first = await repository.getAnnouncements();
      final cached = await repository.getAnnouncements();
      repository.clearCache();
      final refetched = await repository.getAnnouncements();

      expect(cached.announcements, first.announcements);
      expect(refetched.announcements, first.announcements);
    });

    test('memberikan data fallback untuk ID yang tidak ada di storage', () async {
      final repository = AnnouncementRepositoryImpl()..clearCache();

      final result = await repository.getAnnouncementById('99');

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement!.id, '99');
      expect(result.announcement!.title, 'Pengumuman #99');
      expect(result.announcement!.date, '-');
    });
  });

  group('AnnouncementModel - mapping data', () {
    test('menghasilkan nilai default untuk field yang tidak lengkap', () {
      final model = AnnouncementModel.fromMap(const {}, defaultId: '7');

      expect(model.id, '7');
      expect(model.title, isEmpty);
      expect(model.body, isEmpty);
      expect(model.date, isEmpty);
      expect(model.imageUrl, isNull);
    });

    test('mempertahankan imageUrl saat serialisasi dan deserialisasi', () {
      const model = AnnouncementModel(
        id: '5',
        title: 'Banner Kampus',
        body: 'Pengumuman dengan gambar',
        date: '18 November 2026',
        imageUrl: 'https://example.com/banner.png',
      );

      final roundTrip = AnnouncementModel.fromMap(model.toMap());

      expect(roundTrip.imageUrl, 'https://example.com/banner.png');
      expect(roundTrip.toEntity().imageUrl, 'https://example.com/banner.png');
    });
  });
}
