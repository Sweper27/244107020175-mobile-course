import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../providers.dart';

class CommentRepository {
  final Dio _dio;
  CommentRepository(this._dio);

  /// Mengambil daftar komentar berdasarkan [postId]
  Future<List<Comment>> fetchComments(int postId) async {
    // Memanggil API dengan query parameters: GET /comments?postId={id}
    // Options cancelToken/timeout bawaan Dio 10 detik dari dioProvider otomatis berlaku
    final response = await _dio.get(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Casting aman untuk mencegah crash jika response.data bukan List atau null
    final data = response.data as List?;
    if (data == null) return [];

    // Filter elemen bertipe Map lalu konversi ke Model Comment
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}

// Provider Dependency Injection untuk CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(dioProvider));
});