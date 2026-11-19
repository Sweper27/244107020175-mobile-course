import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:campus_notification/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit test fitur AI (JS 12).
///
/// Data source diganti dengan fake sehingga tidak ada panggilan ke Gemini API
/// dan tidak ada API key yang dibutuhkan.
class FakeAIRemoteDataSource implements AIRemoteDataSource {
  FakeAIRemoteDataSource({this.responseText = 'Balasan dari fake', this.error});

  final String responseText;
  final Exception? error;

  int callCount = 0;
  String? lastPrompt;

  @override
  Future<String> generateTextResponse(String prompt) async {
    callCount++;
    lastPrompt = prompt;
    if (error != null) throw error!;
    return responseText;
  }
}

void main() {
  group('AIRepositoryImpl - fake data source', () {
    test('mengembalikan AIMessage non-user saat balasan berhasil', () async {
      // Arrange
      final dataSource = FakeAIRemoteDataSource(responseText: 'Halo, ada yang bisa dibantu?');
      final repository = AIRepositoryImpl(dataSource);

      // Act
      final message = await repository.sendPrompt('Halo AI');

      // Assert
      expect(dataSource.callCount, 1);
      expect(dataSource.lastPrompt, 'Halo AI');
      expect(message.isUser, isFalse);
      expect(message.text, 'Halo, ada yang bisa dibantu?');
      expect(message.id, isNotEmpty);
    });

    test('mengubah exception data source menjadi AIFailure yang rapi', () async {
      final dataSource = FakeAIRemoteDataSource(
        error: Exception('Kesalahan Gemini API: kuota habis'),
      );
      final repository = AIRepositoryImpl(dataSource);

      await expectLater(
        repository.sendPrompt('Halo AI'),
        throwsA(
          isA<AIFailure>().having(
            (failure) => failure.message,
            'message',
            'Kesalahan Gemini API: kuota habis',
          ),
        ),
      );
    });
  });

  group('AIRemoteDataSourceImpl - tanpa API key', () {
    test('memberikan mode simulasi saat API key kosong', () async {
      // Arrange: environment dibuat tanpa GEMINI_API_KEY.
      dotenv.testLoad(fileInput: 'GEMINI_API_KEY=');
      final dataSource = AIRemoteDataSourceImpl();

      // Act
      final response = await dataSource.generateTextResponse('Apa itu Flutter?');

      // Assert
      expect(response, contains('[Mode Simulasi AI]'));
      expect(response, contains('Apa itu Flutter?'));
    });

    test('memberikan mode simulasi saat API key masih placeholder', () async {
      dotenv.testLoad(
        fileInput: 'GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE',
      );
      final dataSource = AIRemoteDataSourceImpl();

      final response = await dataSource.generateTextResponse('Halo');

      expect(response, contains('[Mode Simulasi AI]'));
    });
  });
}
