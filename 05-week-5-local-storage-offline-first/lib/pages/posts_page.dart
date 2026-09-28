import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/offline_provider.dart';
import '../data/post.dart';
import '../data/repositories/post_repository.dart';

final postRepositoryProvider =
    Provider<PostRepository>(
  (ref) => PostRepository(),
);

final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

class PostsNotifier
    extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repository =
        ref.read(postRepositoryProvider);

    final cached =
        await repository.readCachedPosts();

    final forceOffline =
        ref.read(forceOfflineProvider);

    if (!forceOffline) {
      unawaited(
        _refreshInBackground(repository),
      );
    }

    return cached;
  }

  Future<void> _refreshInBackground(
    PostRepository repository,
  ) async {
    try {
      final posts =
          await repository.refreshFromNetwork();

      state = AsyncData(posts);
    } catch (_) {
      // Kalau jaringan gagal, cache tetap dipakai.
    }
  }

  Future<void> refresh() async {
    final repository =
        ref.read(postRepositoryProvider);

    final forceOffline =
        ref.read(forceOfflineProvider);

    if (forceOffline) {
      return;
    }

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return repository.refreshFromNetwork();
    });
  }
}

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final postsState =
        ref.watch(postsProvider);

    final forceOffline =
        ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Posts'),
        actions: [
          if (forceOffline)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.cloud_off,
              ),
            ),

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: forceOffline
                ? null
                : () async {
                    await ref
                        .read(postsProvider.notifier)
                        .refresh();
                  },
          ),
        ],
      ),

      body: postsState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal membaca data:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },

        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada cache posts.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(postsProvider.notifier)
                  .refresh();
            },

            child: ListView.separated(
              padding: const EdgeInsets.all(12),

              itemCount: posts.length,

              separatorBuilder: (_, _) {
                return const SizedBox(
                  height: 8,
                );
              },

              itemBuilder:
                  (context, index) {
                final post =
                    posts[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        '${post.id}',
                      ),
                    ),

                    title: Text(
                      post.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),

                    subtitle: Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 6,
                      ),
                      child: Text(
                        post.body,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}