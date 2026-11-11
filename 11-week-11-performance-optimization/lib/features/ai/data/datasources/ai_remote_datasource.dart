import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

abstract class AIRemoteDataSource {
  Future<String> generateTextResponse(String prompt);
}

class AIRemoteDataSourceImpl implements AIRemoteDataSource {
  AIRemoteDataSourceImpl({this.model});

  GenerativeModel? model;

  GenerativeModel _getModel() {
    if (model != null) return model!;

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        'GEMINI_API_KEY belum dikonfigurasi. Silakan isi file .env dengan API Key dari Google AI Studio.',
      );
    }

    model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
    );
    return model!;
  }

  @override
  Future<String> generateTextResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    // Fallback ramah jika user belum mengisi API Key di .env
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return '[Mode Simulasi AI]\nAPI Key belum diisi di file .env.\n'
          'Pertanyaan Anda: "$prompt"\n\n'
          'Untuk menghubungkan dengan Gemini AI sungguhan, masukkan API Key gratis Anda pada file .env (GEMINI_API_KEY=...).';
    }

    try {
      final activeModel = _getModel();
      final content = [Content.text(prompt)];
      final response = await activeModel.generateContent(content);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Model AI tidak mengembalikan respon teks.');
      }
      return responseText;
    } on GenerativeAIException catch (e) {
      throw Exception('Kesalahan Gemini API: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghubungi layanan AI: $e');
    }
  }
}
