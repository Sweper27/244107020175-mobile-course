import '../../../../core/failures.dart';
import '../entities/ai_message.dart';
import '../repositories/ai_repository.dart';

class SendPromptUseCase {
  const SendPromptUseCase(this._repository);

  final AIRepository _repository;

  Future<AIMessage> call(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw const AIFailure('Prompt tidak boleh kosong');
    }
    return _repository.sendPrompt(trimmedPrompt);
  }
}
