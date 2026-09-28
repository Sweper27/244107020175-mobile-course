import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/offline_provider.dart';
import '../data/theme_provider.dart';

class SettingsPage
    extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final isDark =
        ref.watch(darkModeProvider);

    final forceOffline =
        ref.watch(
          forceOfflineProvider,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
        ),
      ),

      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(
              'Dark Mode',
            ),
            subtitle: const Text(
              'Simpan preferensi tema '
              'secara lokal',
            ),
            value: isDark,
            onChanged: (_) {
              ref
                  .read(
                    darkModeProvider
                        .notifier,
                  )
                  .toggle();
            },
          ),

          const Divider(),

          SwitchListTile(
            title: const Text(
              'Force Offline',
            ),
            subtitle: const Text(
              'Simulasikan perangkat '
              'tanpa internet',
            ),
            value: forceOffline,
            onChanged: (_) {
              ref
                  .read(
                    forceOfflineProvider
                        .notifier,
                  )
                  .toggle();
            },
          ),

          if (forceOffline)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mode offline aktif. '
                          'Data lokal tetap '
                          'dapat digunakan.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.article_outlined,
            ),
            title: const Text(
              'Cached Posts',
            ),
            subtitle: const Text(
              'Cache-first GET /posts',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              context.push(
                '/posts',
              );
            },
          ),
        ],
      ),
    );
  }
}