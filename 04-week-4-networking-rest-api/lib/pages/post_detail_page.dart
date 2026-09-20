import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_provider.dart';
import '../data/models/post.dart';

class PostDetailPage extends ConsumerWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentListProvider(post.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Post #${post.id}'),
      ),
      body: Column(
        children: [
          // Header Informasi Post
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest, // Perbaikan 1
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(post.body),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.comment_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Komentar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Daftar Komentar dari API
          Expanded(
            child: commentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(getFriendlyErrorMessage(err)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Belum ada komentar untuk post ini.'),
                  );
                }
                return ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1), // Perbaikan 2
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(
                        comment.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.email,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.indigo),
                          ),
                          const SizedBox(height: 4),
                          Text(comment.body),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}