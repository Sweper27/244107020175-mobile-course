import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/features/announcements/data/models/announcement_model.dart';
import 'package:campus_notification/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notification/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notification/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notification/features/auth/presentation/pages/home_page.dart';

void main() {
  group('Jobsheet 11 Performance Optimization Tests', () {
    test('1. AnnouncementRepositoryImpl: Stale-While-Revalidate Cache Verification', () async {
      final repository = AnnouncementRepositoryImpl();
      repository.clearCache();

      // First fetch: Cache Miss (takes simulated latency ~150ms)
      final stopwatch1 = Stopwatch()..start();
      final result1 = await repository.getAnnouncements();
      stopwatch1.stop();

      expect(result1.failure, isNull);
      expect(result1.announcements.isNotEmpty, isTrue);
      expect(stopwatch1.elapsedMilliseconds, greaterThanOrEqualTo(100));

      // Second fetch: Cache Hit (instant response < 30ms)
      final stopwatch2 = Stopwatch()..start();
      final result2 = await repository.getAnnouncements();
      stopwatch2.stop();

      expect(result2.failure, isNull);
      expect(result2.announcements.length, equals(result1.announcements.length));
      expect(stopwatch2.elapsedMilliseconds, lessThan(80));

      // Fetch by ID cache hit
      final idResult1 = await repository.getAnnouncementById('1');
      expect(idResult1.announcement?.id, equals('1'));

      final stopwatchId = Stopwatch()..start();
      final idResult2 = await repository.getAnnouncementById('1');
      stopwatchId.stop();

      expect(idResult2.announcement?.id, equals('1'));
      expect(stopwatchId.elapsedMilliseconds, lessThan(80));
    });

    test('2. AnnouncementModel: Image URL Serialization and Entity Mapping', () {
      final model = AnnouncementModel(
        id: '99',
        title: 'Optimasi Gambar',
        body: 'Materi CachedNetworkImage dengan batasan memCacheWidth',
        date: '10 November 2026',
        imageUrl: 'https://example.com/banner.png',
      );

      final map = model.toMap();
      expect(map['imageUrl'], equals('https://example.com/banner.png'));

      final deserialized = AnnouncementModel.fromMap(map);
      expect(deserialized.imageUrl, equals('https://example.com/banner.png'));

      final entity = deserialized.toEntity();
      expect(entity.imageUrl, equals('https://example.com/banner.png'));
    });

    testWidgets('3. HomePage: Render with Lazy SliverList and RepaintBoundary', (tester) async {
      const sampleAnnouncements = [
        Announcement(
          id: '1',
          title: 'Pengumuman 1',
          body: 'Isi pengumuman 1',
          date: '10 November 2026',
          imageUrl: 'https://example.com/img1.png',
        ),
        Announcement(
          id: '2',
          title: 'Pengumuman 2',
          body: 'Isi pengumuman 2',
          date: '11 November 2026',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsListProvider.overrideWith(
              (ref) => Future.value(sampleAnnouncements),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Lazy Scroll Structure
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Verify RepaintBoundary is applied to isolate widget repaints
      expect(find.byType(RepaintBoundary), findsWidgets);

      // Verify Cards exist
      expect(find.text('Pengumuman 1'), findsOneWidget);
      expect(find.text('Pengumuman 2'), findsOneWidget);
    });
  });
}
