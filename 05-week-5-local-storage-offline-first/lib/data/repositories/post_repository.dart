import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../post.dart';

class PostRepository {
  PostRepository({
    Future<Database> Function()? openDb,
    Dio? dio,
  })  : _openDb = openDb ?? openNotesDb,
        _dio = dio ?? Dio();

  final Future<Database> Function() _openDb;
  final Dio _dio;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();

    final rows = await db.query(
      'cached_posts',
      orderBy: 'cached_at DESC',
    );

    return rows.map((row) {
      final payload =
          jsonDecode(row['payload'] as String)
              as Map<String, dynamic>;

      return Post(
        id: (payload['id'] as num).toInt(),
        title: payload['title'] as String? ?? '',
        body: payload['body'] as String? ?? '',
        cachedAt: DateTime.tryParse(
              row['cached_at'] as String? ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  Future<List<Post>> fetchPostsFromNetwork() async {
    final response = await _dio.get(
      'https://jsonplaceholder.typicode.com/posts',
    );

    final data = response.data as List;

    return data
        .map(
          (item) => Post.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> savePostsToCache(
    List<Post> posts,
  ) async {
    final db = await _openDb();

    await db.delete('cached_posts');

    final now = DateTime.now().toIso8601String();

    final batch = db.batch();

    for (final post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm:
            ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Post>> refreshFromNetwork() async {
    final posts =
        await fetchPostsFromNetwork();

    await savePostsToCache(posts);

    return readCachedPosts();
  }
}