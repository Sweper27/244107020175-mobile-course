import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../announcements/domain/entities/announcement.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../providers/auth_providers.dart';

/// Clean Architecture Home page optimized for performance (JS 11).
///
/// Performance Optimizations Applied:
/// 1. Widget Rebuild Isolation: Extracted static/heavy sections (_WelcomeCard, _AnnouncementSearchBar,
///    _AnnouncementCardItem) into dedicated `const` widgets.
/// 2. Riverpod .select() & Granular Watching: Search query listening is localized,
///    preventing entire HomePage scaffold and app bar from rebuilding on every keystroke.
/// 3. Lazy Loading & Paint Boundary: Eager Column rendering replaced with lazy `SliverList.builder`,
///    and individual cards are wrapped in `RepaintBoundary` to isolate GPU rasterization.
/// 4. Image Optimization: Integrated `CachedNetworkImage` with `memCacheWidth` / `memCacheHeight`
///    to avoid full-resolution memory decoding and redundant network fetches.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    // Memory Optimization: Clean up controllers to prevent memory leaks
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetSearch() {
    _searchController.clear();
    ref.read(announcementSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notification'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Assistant',
            onPressed: () => context.push('/ai-chat'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Optimization: Const widget extraction isolates build tree
                  _WelcomeCard(
                    onLogout: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Daftar Pengumuman Kampus',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Optimization: Localized search bar prevents whole page rebuild
                  _AnnouncementSearchBar(
                    controller: _searchController,
                    onReset: _resetSearch,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Optimization: Granular consumer for announcements list
          _AnnouncementSliverSection(
            searchController: _searchController,
            onResetSearch: _resetSearch,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-chat'),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Tanya AI'),
      ),
    );
  }
}

/// Extracted Welcome Card with const constructor to prevent rebuilds.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Selamat datang!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Anda berhasil login sebagai Mahasiswa.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted search bar utilizing Riverpod .select() for minimal rebuilds.
class _AnnouncementSearchBar extends ConsumerWidget {
  const _AnnouncementSearchBar({
    required this.controller,
    required this.onReset,
  });

  final TextEditingController controller;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimization: .select ensures rebuild only occurs when query becomes empty or non-empty
    final hasQuery = ref.watch(
      announcementSearchQueryProvider.select((query) => query.isNotEmpty),
    );

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari judul atau isi pengumuman...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasQuery
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Hapus pencarian',
                onPressed: onReset,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
      onChanged: (value) {
        ref.read(announcementSearchQueryProvider.notifier).state = value;
      },
    );
  }
}

/// Sliver section displaying announcements with lazy loading and paint isolation.
class _AnnouncementSliverSection extends ConsumerWidget {
  const _AnnouncementSliverSection({
    required this.searchController,
    required this.onResetSearch,
  });

  final TextEditingController searchController;
  final VoidCallback onResetSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredAnnouncementsProvider);
    final searchQuery = ref.watch(announcementSearchQueryProvider);

    return filteredAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Gagal memuat pengumuman: $err'),
          ),
        ),
      ),
      data: (announcements) {
        if (announcements.isEmpty) {
          if (searchQuery.isNotEmpty) {
            return SliverToBoxAdapter(
              child: _AnnouncementEmptySearchResult(
                query: searchQuery,
                onReset: onResetSearch,
              ),
            );
          }
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tidak ada pengumuman.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        // Optimization: Lazy Loading using SliverList.builder inside SliverPadding
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];
              // Optimization: RepaintBoundary isolates paint layer during scroll
              return RepaintBoundary(
                child: _AnnouncementCardItem(
                  item: item,
                  onTap: () => context.push('/pengumuman/${item.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Extracted announcement card item with RepaintBoundary and CachedNetworkImage.
class _AnnouncementCardItem extends StatelessWidget {
  const _AnnouncementCardItem({
    required this.item,
    required this.onTap,
  });

  final Announcement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  // Optimization: Limit memory decode resolution to exact thumbnail size
                  memCacheWidth: 144,
                  memCacheHeight: 144,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      '#${item.id}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  '#${item.id}',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              item.date,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

/// Extracted empty search state with const widgets.
class _AnnouncementEmptySearchResult extends StatelessWidget {
  const _AnnouncementEmptySearchResult({
    required this.query,
    required this.onReset,
  });

  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Pengumuman tidak ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada pengumuman yang cocok dengan kata kunci "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }
}
