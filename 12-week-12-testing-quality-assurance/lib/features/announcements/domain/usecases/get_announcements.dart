import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case for fetching the list of all announcements.
class GetAnnouncements {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  Future<({List<Announcement> announcements, Failure? failure})> call() {
    return _repository.getAnnouncements();
  }
}
