import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'repositories/comment_repository.dart';

// FutureProvider.family adalah pilihan paling stabil & bersih di Riverpod 2.x
// untuk pemanggilan data asinkron berparameter tanpa boilerplate berlebih
final commentListProvider =
    FutureProvider.family<List<Comment>, int>((ref, postId) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.fetchComments(postId);
});

/// Helper menterjemahkan DioException menjadi pesan yang ramah pengguna
String getFriendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau terputus (Timeout). Periksa internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code == 404) return 'Komentar tidak ditemukan (404).';
        if (code >= 500) {
          return 'Server sedang bermasalah ($code). Coba lagi nanti.';
        }
        return 'Terjadi kesalahan respons HTTP ($code).';
      default:
        return 'Terjadi kesalahan jaringan yang tidak diketahui.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}