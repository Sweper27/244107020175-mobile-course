/// Pure Dart entity representing a campus announcement.
/// Business object free from database or serialization logic.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  final String id;
  final String title;
  final String body;
  final String date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          date == other.date;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ body.hashCode ^ date.hashCode;
}
