import '../entities/ai_message.dart';

abstract class AIRepository {
  Future<AIMessage> sendPrompt(String prompt);
}
