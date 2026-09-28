import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note_repository.dart';

final noteRepositoryProvider =
    Provider<NoteRepository>(
  (ref) => NoteRepository(),
);