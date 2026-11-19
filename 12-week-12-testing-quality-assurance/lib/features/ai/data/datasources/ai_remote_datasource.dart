import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/config/env_config.dart';

abstract class AIRemoteDataSource {
  Future<String> generateTextResponse(String prompt);
}

class AIRemoteDataSourceImpl implements AIRemoteDataSource {
  AIRemoteDataSourceImpl({this.model});

  GenerativeModel? model;

  GenerativeModel _getModel() {
    if (model != null) return model!;

    // Konfigurasi terpusat: API key dan nama model dibaca dari `.env` (JS 12).
    final apiKey = EnvConfig.geminiApiKey;
    if (!EnvConfig.hasGeminiApiKey) {
      throw Exception(
        'GEMINI_API_KEY belum dikonfigurasi. Silakan isi file .env dengan API Key dari Google AI Studio.',
      );
    }

    model = GenerativeModel(
      model: EnvConfig.geminiModel,
      apiKey: apiKey,
    );
    return model!;
  }

  @override
  Future<String> generateTextResponse(String prompt) async {
    // Fallback ramah jika user belum mengisi API Key di .env
    if (!EnvConfig.hasGeminiApiKey) {
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
