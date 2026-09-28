import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/offline_provider.dart';
import '../data/repositories/providers.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier
    extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    return ref
        .read(noteRepositoryProvider)
        .fetchNotes();
  }

  Future<void> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final repository =
          ref.read(noteRepositoryProvider);

      final newNote =
          await repository.addNote(
        title: title,
        body: body,
      );

      final currentNotes =
          state.value ?? <Note>[];

      state = AsyncData([
        newNote,
        ...currentNotes,
      ]);
    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final repository =
          ref.read(noteRepositoryProvider);

      await repository.deleteNote(id);

      final currentNotes =
          state.value ?? <Note>[];

      state = AsyncData(
        currentNotes
            .where(
              (note) => note.id != id,
            )
            .toList(),
      );
    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );
    }
  }

  Future<int> syncNow() async {
    try {
      final repository =
          ref.read(noteRepositoryProvider);

      final syncedCount =
          await syncNotes(repository);

      final notes =
          await repository.fetchNotes();

      state = AsyncData(notes);

      return syncedCount;
    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );

      rethrow;
    }
  }
}

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final notesState =
        ref.watch(notesProvider);

    final forceOffline =
        ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Text(
              'Offline Notes',
            ),
            if (forceOffline) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.cloud_off,
                size: 18,
              ),
            ],
          ],
        ),

        actions: [
          notesState.when(
            loading: () =>
                const SizedBox.shrink(),

            error: (_, _) =>
                const SizedBox.shrink(),

            data: (notes) {
              final dirtyCount =
                  notes
                      .where(
                        (note) => note.dirty,
                      )
                      .length;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 4,
                ),
                child: Center(
                  child: Text(
                    dirtyCount == 0
                        ? 'Tersinkron'
                        : 'Belum sync: '
                            '$dirtyCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: dirtyCount == 0
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              );
            },
          ),

          IconButton(
            tooltip:
                'Sinkronisasi',
            icon:
                const Icon(Icons.sync),
            onPressed: () async {
              if (forceOffline) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Force Offline aktif. '
                      'Matikan mode offline '
                      'sebelum sinkronisasi.',
                    ),
                  ),
                );

                return;
              }

              try {
                final synced =
                    await ref
                        .read(
                          notesProvider
                              .notifier,
                        )
                        .syncNow();

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      synced == 0
                          ? 'Tidak ada catatan '
                              'yang perlu '
                              'disinkronkan.'
                          : '$synced catatan '
                              'berhasil '
                              'disinkronkan.',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sinkronisasi gagal: $e',
                    ),
                  ),
                );
              }
            },
          ),

          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),

      body: notesState.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),

        error: (
          error,
          stackTrace,
        ) =>
            Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Terjadi kesalahan:\n'
                  '$error',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(
                      notesProvider,
                    );
                  },
                  child: const Text(
                    'Coba Lagi',
                  ),
                ),
              ],
            ),
          ),
        ),

        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada catatan.\n'
                'Tekan + untuk menambahkan.',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                notesProvider,
              );

              await ref.read(
                notesProvider.future,
              );
            },

            child:
                ListView.separated(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  notes.length,

              separatorBuilder: (
                _,
                _,
              ) =>
                  const SizedBox(
                height: 8,
              ),

              itemBuilder: (
                context,
                index,
              ) {
                final note =
                    notes[index];

                return NoteTile(
                  note: note,

                  onTap: note.id == null
                      ? null
                      : () {
                          context.push(
                            '/note/${note.id}',
                          );
                        },

                  onDelete: () {
                    _confirmDelete(
                      context,
                      ref,
                      note,
                    );
                  },
                );
              },
            ),
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddNotePage(),
            ),
          );
        },
        child:
            const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus catatan?',
          ),
          content: Text(
            'Catatan "${note.title}" '
            'akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Batal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (note.id == null) {
      return;
    }

    await ref
        .read(notesProvider.notifier)
        .deleteNote(note.id!);
  }
}

class AddNotePage
    extends ConsumerStatefulWidget {
  const AddNotePage({super.key});

  @override
  ConsumerState<AddNotePage>
      createState() =>
          _AddNotePageState();
}

class _AddNotePageState
    extends ConsumerState<AddNotePage> {
  final titleController =
      TextEditingController();

  final bodyController =
      TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();

    super.dispose();
  }

  Future<void> saveNote() async {
    final title =
        titleController.text.trim();

    final body =
        bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Judul tidak boleh kosong.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await ref
          .read(notesProvider.notifier)
          .addNote(
            title: title,
            body: body,
          );

      if (!mounted) {
        return;
      }

      context.pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Catatan',
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller:
                  titleController,
              autofocus: true,
              decoration:
                  const InputDecoration(
                labelText: 'Judul',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  bodyController,
              maxLines: 8,
              decoration:
                  const InputDecoration(
                labelText:
                    'Isi catatan',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : saveNote,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  isSaving
                      ? 'Menyimpan...'
                      : 'Simpan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}