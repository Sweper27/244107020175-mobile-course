import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model Unit Tests', () {
    test('fromJson berhasil memetakan JSON normal (Happy Path)', () {
      final json = {
        'postId': 1,
        'id': 10,
        'name': 'Budi',
        'email': 'budi@mail.com',
        'body': 'Komentar tes'
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 10);
      expect(comment.name, 'Budi');
      expect(comment.email, 'budi@mail.com');
      expect(comment.body, 'Komentar tes');
    });

    test('fromJson aman ketika field hilang, bernilai null, atau salah tipe (Edge Case)', () {
      final badJson = {
        'postId': null, // null num
        // 'id' dihilangkan total (missing key)
        'name': null,   // null String
        'email': 12345, // tipe int pada field String
        // 'body' dihilangkan total
      };

      final comment = Comment.fromJson(badJson);

      // Verifikasi fallback default yang aman
      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '12345'); // Diubah aman menjadi String lewat .toString()
      expect(comment.body, '');
    });
  });
}