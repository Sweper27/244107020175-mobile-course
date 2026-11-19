import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/ai/domain/entities/ai_message.dart';
import 'package:campus_notification/features/ai/domain/repositories/ai_repository.dart';
import 'package:campus_notification/features/ai/domain/usecases/send_prompt_usecase.dart';
import 'package:campus_notification/features/ai/presentation/providers/ai_providers.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAIRepository implements AIRepository {
  MockAIRepository({this.shouldFail = false, this.responseText = 'Mock AI response'});

  final bool shouldFail;
  final String responseText;

  @override
  Future<AIMessage> sendPrompt(String prompt) async {
    if (shouldFail) {
      throw const AIFailure('Gagal memproses prompt');
    }
    return AIMessage(
      id: 'mock-id-123',
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  group('SendPromptUseCase Tests', () {
    test('throws AIFailure when prompt is empty or blank', () async {
      final repository = MockAIRepository();
      final useCase = SendPromptUseCase(repository);

      expect(
        () => useCase('   '),
        throwsA(isA<AIFailure>()),
      );
    });

    test('returns AIMessage when prompt is valid', () async {
      final repository = MockAIRepository(responseText: 'Halo! Ada yang bisa saya bantu?');
      final useCase = SendPromptUseCase(repository);

      final result = await useCase('Halo Gemini');

      expect(result.text, equals('Halo! Ada yang bisa saya bantu?'));
      expect(result.isUser, isFalse);
    });
  });

  group('AIChatNotifier Tests', () {
    test('initial state has empty messages and not loading', () {
      final repository = MockAIRepository();
      final useCase = SendPromptUseCase(repository);
      final notifier = AIChatNotifier(useCase);

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('sendMessage updates state with user message and AI response', () async {
      final repository = MockAIRepository(responseText: 'Jawaban dari AI');
      final useCase = SendPromptUseCase(repository);
      final notifier = AIChatNotifier(useCase);

      await notifier.sendMessage('Pertanyaan user');

      expect(notifier.state.messages.length, equals(2));
      expect(notifier.state.messages[0].isUser, isTrue);
      expect(notifier.state.messages[0].text, equals('Pertanyaan user'));
      expect(notifier.state.messages[1].isUser, isFalse);
      expect(notifier.state.messages[1].text, equals('Jawaban dari AI'));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('sendMessage sets errorMessage on failure', () async {
      final repository = MockAIRepository(shouldFail: true);
      final useCase = SendPromptUseCase(repository);
      final notifier = AIChatNotifier(useCase);

      await notifier.sendMessage('Pertanyaan gagal');

      expect(notifier.state.messages.length, equals(1)); // user message only
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, contains('Gagal memproses prompt'));
    });

    test('clearChat resets state to initial', () async {
      final repository = MockAIRepository();
      final useCase = SendPromptUseCase(repository);
      final notifier = AIChatNotifier(useCase);

      await notifier.sendMessage('Pertanyaan');
      notifier.clearChat();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
