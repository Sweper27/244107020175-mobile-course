import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/theme_provider.dart';
import 'pages/note_detail_page.dart';
import 'pages/notes_page.dart';
import 'pages/posts_page.dart';
import 'pages/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  routes: [
    GoRoute(
      path: '/',
      builder: (
        context,
        state,
      ) {
        return const NotesPage();
      },
    ),

    GoRoute(
      path: '/settings',
      builder: (
        context,
        state,
      ) {
        return const SettingsPage();
      },
    ),

    GoRoute(
      path: '/posts',
      builder: (
        context,
        state,
      ) {
        return const PostsPage();
      },
    ),

    GoRoute(
      path: '/note/:id',
      builder: (
        context,
        state,
      ) {
        final id = int.tryParse(
          state.pathParameters['id'] ?? '',
        );

        if (id == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'ID catatan tidak valid.',
              ),
            ),
          );
        }

        return NoteDetailPage(
          noteId: id,
        );
      },
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs =
      await SharedPreferences.getInstance();

  final savedDarkMode =
      prefs.getBool('dark_mode') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        initialDarkModeProvider
            .overrideWithValue(
          savedDarkMode,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp
    extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final isDark =
        ref.watch(darkModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner:
          false,

      title: 'Offline Notes',

      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness:
              Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness:
              Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: isDark
          ? ThemeMode.dark
          : ThemeMode.light,

      routerConfig: appRouter,
    );
  }
}