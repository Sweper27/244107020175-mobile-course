import '../../../../core/failures.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

class AIRepositoryImpl implements AIRepository {
  const AIRepositoryImpl(this._remoteDataSource);

  final AIRemoteDataSource _remoteDataSource;

  @override
  Future<AIMessage> sendPrompt(String prompt) async {
    try {
      final responseText = await _remoteDataSource.generateTextResponse(prompt);
      return AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw AIFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
