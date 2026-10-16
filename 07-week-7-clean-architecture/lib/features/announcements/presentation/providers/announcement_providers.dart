import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_by_id.dart';
import '../../domain/usecases/get_announcements.dart';

/// Data layer provider: supplies concrete repository.
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

/// Domain layer provider: GetAnnouncementById usecase.
final getAnnouncementByIdProvider = Provider<GetAnnouncementById>((ref) {
  return GetAnnouncementById(ref.watch(announcementRepositoryProvider));
});

/// Domain layer provider: GetAnnouncements usecase.
final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

/// Presentation state provider for a single announcement by ID.
final announcementDetailProvider = FutureProvider.family<Announcement, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getAnnouncementByIdProvider);
  final result = await useCase(id);

  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }

  return result.announcement!;
});

/// Presentation state provider for announcements list.
final announcementsListProvider = FutureProvider<List<Announcement>>((
  ref,
) async {
  final useCase = ref.watch(getAnnouncementsProvider);
  final result = await useCase();

  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }

  return result.announcements;
});
