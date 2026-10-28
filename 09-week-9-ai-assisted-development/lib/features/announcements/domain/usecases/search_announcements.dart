import '../entities/announcement.dart';

/// Use case murni untuk memfilter daftar pengumuman berdasarkan kata kunci pencarian.
/// Logika bisnis terisolasi dari UI dan data source, mematuhi prinsip Clean Architecture.
class SearchAnnouncements {
  const SearchAnnouncements();

  /// Menyaring [announcements] berdasarkan [query].
  ///
  /// - Jika [query] kosong atau hanya terdiri dari spasi, mengembalikan seluruh daftar asli.
  /// - Melakukan pencarian case-insensitive pada [Announcement.title] dan [Announcement.body].
  /// - Mengabaikan whitespace di awal dan akhir query pencarian.
  List<Announcement> call({
    required List<Announcement> announcements,
    required String query,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return announcements;
    }

    return announcements.where((item) {
      final titleMatch = item.title.toLowerCase().contains(cleanQuery);
      final bodyMatch = item.body.toLowerCase().contains(cleanQuery);
      return titleMatch || bodyMatch;
    }).toList();
  }
}
