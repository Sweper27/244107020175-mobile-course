import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

// Nilai awal akan diisi dari SharedPreferences
// sebelum aplikasi dijalankan.
final initialDarkModeProvider = Provider<bool>(
  (ref) => false,
);

class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(initialDarkModeProvider);
  }

  Future<void> toggle() async {
    final next = !state;

    // Update UI langsung.
    state = next;

    // Simpan ke local storage.
    await ref
        .read(prefsRepositoryProvider)
        .setDarkMode(next);
  }
}

final darkModeProvider =
    NotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);