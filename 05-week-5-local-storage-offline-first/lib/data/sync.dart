import 'repositories/note_repository.dart';

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  // Simulasi proses upload ke server.
  await Future.delayed(
    const Duration(seconds: 1),
  );

  // Jika server dianggap berhasil,
  // semua catatan dirty ditandai sudah tersinkron.
  await repo.markAllSynced();

  return dirtyCount;
}