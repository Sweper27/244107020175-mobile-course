import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/providers.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  final int noteId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final repository =
        ref.read(noteRepositoryProvider);

    return FutureBuilder<Note?>(
      future: repository.fetchNoteById(noteId),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Detail Catatan',
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal membaca catatan:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final note = snapshot.data;

        if (note == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Detail Catatan',
              ),
            ),
            body: const Center(
              child: Text(
                'Catatan tidak ditemukan.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Detail Catatan',
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    if (note.dirty)
                      const Chip(
                        label: Text(
                          'Belum tersinkron',
                        ),
                        avatar: Icon(
                          Icons.cloud_off,
                          size: 18,
                        ),
                      )
                    else
                      const Chip(
                        label: Text(
                          'Tersinkron',
                        ),
                        avatar: Icon(
                          Icons.cloud_done,
                          size: 18,
                        ),
                      ),

                    const SizedBox(width: 8),

                    Text(
                      _formatDate(
                        note.updatedAt,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  note.body.isEmpty
                      ? 'Tidak ada isi catatan.'
                      : note.body,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    final day = local.day
        .toString()
        .padLeft(2, '0');

    final month = local.month
        .toString()
        .padLeft(2, '0');

    final year = local.year;

    final hour = local.hour
        .toString()
        .padLeft(2, '0');

    final minute = local.minute
        .toString()
        .padLeft(2, '0');

    return '$day/$month/$year '
        '$hour:$minute';
  }
}