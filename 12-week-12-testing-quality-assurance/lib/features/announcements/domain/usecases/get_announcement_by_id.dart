import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case for fetching a specific announcement by its ID.
class GetAnnouncementById {
  const GetAnnouncementById(this._repository);

  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(String id) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      return Future.value((
        announcement: null,
        failure: const NotFoundFailure('ID pengumuman tidak valid'),
      ));
    }
    return _repository.getAnnouncementById(cleanId);
  }
}
