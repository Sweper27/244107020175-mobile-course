import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Concrete implementation of AnnouncementRepository with Stale-While-Revalidate caching.
/// Encapsulates local or remote data source for announcements.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl();

  static final Map<String, Map<String, dynamic>> _storage = {
    '1': {
      'title': 'Registrasi Semester Baru',
      'body': 'Registrasi semester baru telah dibuka. Silakan lengkapi pembayaran dan KRS sebelum tanggal 15 Oktober.',
      'date': '1 Oktober 2026',
      'imageUrl': 'https://picsum.photos/seed/announcement1/400/250',
    },
    '2': {
      'title': 'Pemeliharaan Sistem',
      'body': 'Sistem informasi akademik akan mengalami pemeliharaan pada hari Sabtu, 10 Oktober 2026 pukul 22.00-06.00.',
      'date': '5 Oktober 2026',
      'imageUrl': 'https://picsum.photos/seed/announcement2/400/250',
    },
    '3': {
      'title': 'Jadwal Kuliah Berubah',
      'body': 'Kelas Mobile Programming dipindahkan ke ruang A2 pukul 13.00.',
      'date': '7 Oktober 2026',
      'imageUrl': 'https://picsum.photos/seed/announcement3/400/250',
    },
  };

  // Performance Optimization: In-memory cache for Stale-While-Revalidate strategy
  List<Announcement>? _cachedList;
  final Map<String, Announcement> _cacheMap = {};

  /// Clears the in-memory cache (useful for testing and manual pull-to-refresh).
  void clearCache() {
    _cachedList = null;
    _cacheMap.clear();
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    // 1. Fast path: Stale-While-Revalidate Cache Hit
    if (_cacheMap.containsKey(id)) {
      final cachedItem = _cacheMap[id];
      // Trigger non-blocking background revalidation
      _revalidateAnnouncementById(id);
      return (announcement: cachedItem, failure: null);
    }

    // 2. Cache Miss: fetch from data source
    return _fetchAnnouncementById(id);
  }

  Future<({Announcement? announcement, Failure? failure})> _fetchAnnouncementById(
    String id,
  ) async {
    try {
      // Simulate network latency
      await Future.delayed(const Duration(milliseconds: 150));

      final data = _storage[id];
      if (data != null) {
        final model = AnnouncementModel.fromMap(data, defaultId: id);
        final entity = model.toEntity();
        _cacheMap[id] = entity;
        return (announcement: entity, failure: null);
      }

      // Fallback for unknown ID matching original behavior
      final fallback = AnnouncementModel(
        id: id,
        title: 'Pengumuman #$id',
        body: 'Detail pengumuman dengan ID $id.',
        date: '-',
      );
      final entity = fallback.toEntity();
      _cacheMap[id] = entity;
      return (announcement: entity, failure: null);
    } catch (e) {
      // Offline fallback: if cache exists, return it instead of throwing
      if (_cacheMap.containsKey(id)) {
        return (announcement: _cacheMap[id], failure: null);
      }
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  void _revalidateAnnouncementById(String id) {
    Future(() async {
      final data = _storage[id];
      if (data != null) {
        final model = AnnouncementModel.fromMap(data, defaultId: id);
        _cacheMap[id] = model.toEntity();
      }
    }).ignore();
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    // 1. Fast path: Stale-While-Revalidate Cache Hit (instant UI render, 0ms latency)
    if (_cachedList != null && _cachedList!.isNotEmpty) {
      final cached = List<Announcement>.from(_cachedList!);
      // Trigger background revalidation to keep data fresh
      _revalidateAnnouncements();
      return (announcements: cached, failure: null);
    }

    // 2. Cache Miss: initial fetch
    return _fetchAnnouncements();
  }

  Future<({List<Announcement> announcements, Failure? failure})>
  _fetchAnnouncements() async {
    try {
      // Simulate network latency
      await Future.delayed(const Duration(milliseconds: 150));

      final list = _storage.entries.map((entry) {
        return AnnouncementModel.fromMap(
          entry.value,
          defaultId: entry.key,
        ).toEntity();
      }).toList();

      // Populate local caches
      _cachedList = list;
      for (final item in list) {
        _cacheMap[item.id] = item;
      }

      return (announcements: list, failure: null);
    } catch (e) {
      // Offline fallback: return cached data if available
      if (_cachedList != null) {
        return (announcements: _cachedList!, failure: null);
      }
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat daftar pengumuman: $e'),
      );
    }
  }

  void _revalidateAnnouncements() {
    Future(() async {
      try {
        final freshList = _storage.entries.map((entry) {
          return AnnouncementModel.fromMap(
            entry.value,
            defaultId: entry.key,
          ).toEntity();
        }).toList();

        _cachedList = freshList;
        for (final item in freshList) {
          _cacheMap[item.id] = item;
        }
      } catch (_) {
        // Silently preserve stale cache on background network error
      }
    }).ignore();
  }
}
