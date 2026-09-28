class Post {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.cachedAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime cachedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }

  factory Post.fromJson(
    Map<String, dynamic> json,
  ) {
    return Post(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      cachedAt: DateTime.now(),
    );
  }
}