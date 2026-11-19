import '../../domain/entities/announcement.dart';

/// Data model for Announcement containing JSON/Map serialization and mapping.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.date,
    super.imageUrl,
  });

  factory AnnouncementModel.fromMap(
    Map<String, dynamic> map, {
    String? defaultId,
  }) {
    return AnnouncementModel(
      id: map['id']?.toString() ?? defaultId ?? '0',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      date: map['date'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'date': date,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  Announcement toEntity() => Announcement(
    id: id,
    title: title,
    body: body,
    date: date,
    imageUrl: imageUrl,
  );
}
