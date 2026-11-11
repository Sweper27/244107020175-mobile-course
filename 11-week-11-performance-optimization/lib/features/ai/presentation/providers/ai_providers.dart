import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/send_prompt_usecase.dart';

/// Data Source Provider
final aiRemoteDataSourceProvider = Provider<AIRemoteDataSource>((ref) {
  return AIRemoteDataSourceImpl();
});

/// Repository Provider
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});

/// UseCase Provider
final sendPromptUseCaseProvider = Provider<SendPromptUseCase>((ref) {
  return SendPromptUseCase(ref.watch(aiRepositoryProvider));
});

/// Immutable State for AI Chat
class AIChatState {
  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AIMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  AIChatState copyWith({
    List<AIMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// StateNotifier to manage chat flow, prompt submission, loading, and error states
class AIChatNotifier extends StateNotifier<AIChatState> {
  AIChatNotifier(this._sendPromptUseCase) : super(const AIChatState());

  final SendPromptUseCase _sendPromptUseCase;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 1. Immediately append user message & set loading state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      // 2. Call AI UseCase
      final aiMessage = await _sendPromptUseCase(trimmed);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      // 3. Capture and set error state
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearChat() {
    state = const AIChatState();
  }
}

/// Presentation Provider for UI
final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  return AIChatNotifier(ref.watch(sendPromptUseCaseProvider));
});
