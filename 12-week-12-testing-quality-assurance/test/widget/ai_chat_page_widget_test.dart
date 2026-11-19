import 'dart:async';

import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/ai/domain/usecases/send_prompt_usecase.dart';
import 'package:campus_notification/features/ai/presentation/pages/ai_chat_page.dart';
import 'package:campus_notification/features/ai/presentation/providers/ai_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Widget test halaman AI Assistant (JS 12).
///
/// Use case diganti melalui provider override sehingga tidak ada permintaan
/// ke Gemini API maupun kebutuhan API key saat pengujian.
void main() {
  Widget buildPage(FakeAIRepository repository) {
    return ProviderScope(
      overrides: [
        sendPromptUseCaseProvider.overrideWith(
          (ref) => SendPromptUseCase(repository),
        ),
      ],
      child: const MaterialApp(home: AIChatPage()),
    );
  }

  group('AIChatPage - tampilan awal', () {
    testWidgets('menampilkan empty state dan kolom input', (tester) async {
      await tester.pumpWidget(buildPage(FakeAIRepository()));
      await tester.pumpAndSettle();

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Tanyakan Sesuatu pada AI'), findsOneWidget);
      expect(find.text('Ketik prompt pertanyaan...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });

  group('AIChatPage - interaksi pengguna', () {
    testWidgets('mengirim prompt dan menampilkan balasan AI', (tester) async {
      // Arrange
      final repository = FakeAIRepository(responseText: 'Flutter adalah SDK.');

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), '  Apa itu Flutter?  ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Assert
      expect(repository.sendPromptCallCount, 1);
      expect(repository.lastPrompt, 'Apa itu Flutter?');
      expect(find.text('Apa itu Flutter?'), findsOneWidget);
      expect(find.text('Flutter adalah SDK.'), findsOneWidget);
      expect(find.text('Tanyakan Sesuatu pada AI'), findsNothing);
    });

    testWidgets('menampilkan indikator loading saat menunggu balasan', (
      tester,
    ) async {
      // Arrange
      final gate = Completer<void>();
      final repository = FakeAIRepository(gate: gate);

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'Halo AI');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Assert
      expect(find.text('Sedang memproses...'), findsOneWidget);

      // Cleanup
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Sedang memproses...'), findsNothing);
      expect(find.text('Jawaban simulasi dari AI.'), findsOneWidget);
    });

    testWidgets('menampilkan SnackBar saat layanan AI gagal', (tester) async {
      final repository = FakeAIRepository(
        failure: const AIFailure('Layanan AI sedang sibuk'),
      );

      await tester.pumpWidget(buildPage(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Halo AI');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Layanan AI sedang sibuk'), findsOneWidget);
      // Pesan pengguna tetap tampil meskipun balasan gagal.
      expect(find.text('Halo AI'), findsOneWidget);
    });

    testWidgets('membersihkan percakapan melalui tombol hapus', (tester) async {
      await tester.pumpWidget(buildPage(FakeAIRepository()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Halo AI');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Halo AI'), findsNothing);
      expect(find.text('Tanyakan Sesuatu pada AI'), findsOneWidget);
    });
  });
}
