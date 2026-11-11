import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Repository interface for campus announcements.
/// Pure Dart contract defined in Domain layer.
abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );

  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements();
}
