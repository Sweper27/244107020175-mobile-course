import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/repositories/providers.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({
    this.items = const [],
  }) : super(
          openDb: () async {
            throw UnimplementedError();
          },
        );

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async {
    return items;
  }
}

void main() {
  // ==========================================================
  // TEST 1 - MODEL NOTE
  // ==========================================================

  test(
    'Note.fromMap aman terhadap field yang hilang',
    () {
      final note = Note.fromMap({
        'title': 'Belanja',
      });

      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, false);
    },
  );

  // ==========================================================
  // TEST 2 - PROVIDER DENGAN FAKE REPOSITORY
  // ==========================================================

  test(
    'NotesProvider membaca data dari fake repository',
    () async {
      final container = ProviderContainer.test(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(
              items: [
                Note(
                  title: 'Tes Provider',
                  body: 'Data dari fake repository',
                  updatedAt: DateTime(2026, 9, 28),
                  dirty: true,
                ),
              ],
            ),
          ),
        ],
      );

      final notes = await container.read(
        notesProvider.future,
      );

      expect(notes.length, 1);

      expect(
        notes.first.title,
        'Tes Provider',
      );

      expect(
        notes.first.body,
        'Data dari fake repository',
      );

      expect(
        notes.first.dirty,
        true,
      );
    },
  );
}