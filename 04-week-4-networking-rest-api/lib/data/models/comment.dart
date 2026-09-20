class Comment {
  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  // Factory dari JSON dengan pertahanan penuh terhadap null dan salah tipe data
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // Konversi aman ke int: menangani jika null atau jika angka dikirim sebagai double
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      
      // Konversi aman ke String: toString() mencegah crash jika API mengirim tipe lain (misal int)
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}