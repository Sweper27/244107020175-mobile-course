import 'package:campus_notification/core/config/env_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit test untuk konfigurasi environment terpusat (JS 12).
///
/// Seluruh skenario memakai `dotenv.testLoad` sehingga tidak ada file `.env`
/// asli maupun credential yang dibutuhkan saat pengujian.
void main() {
  group('EnvConfig.read', () {
    test('mengembalikan fallback ketika key tidak tersedia', () {
      // Arrange
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.kampus.ac.id');

      // Act
      final result = EnvConfig.read('KEY_TIDAK_ADA', fallback: 'cadangan');

      // Assert
      expect(result, 'cadangan');
    });

    test('mengembalikan null ketika key tidak tersedia tanpa fallback', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.kampus.ac.id');

      expect(EnvConfig.read('KEY_TIDAK_ADA'), isNull);
    });

    test('memangkas spasi pada nilai environment', () {
      dotenv.testLoad(fileInput: 'GEMINI_MODEL=   gemini-lokal   ');

      expect(EnvConfig.geminiModel, 'gemini-lokal');
    });

    test('menganggap nilai kosong sebagai tidak tersedia', () {
      dotenv.testLoad(fileInput: 'GEMINI_MODEL=');

      expect(EnvConfig.read('GEMINI_MODEL'), isNull);
      expect(EnvConfig.geminiModel, EnvConfig.defaultGeminiModel);
    });
  });

  group('EnvConfig.apiBaseUrl', () {
    test('membaca API_BASE_URL dari environment', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.kampus.ac.id/v1');

      expect(EnvConfig.apiBaseUrl, 'https://api.kampus.ac.id/v1');
      expect(EnvConfig.hasCustomApiBaseUrl, isTrue);
    });

    test('menghapus satu garis miring di akhir URL', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.kampus.ac.id/');

      expect(EnvConfig.apiBaseUrl, 'https://api.kampus.ac.id');
    });

    test('memakai nilai default ketika API_BASE_URL tidak diisi', () {
      dotenv.testLoad(fileInput: 'GEMINI_MODEL=gemini-lokal');

      expect(EnvConfig.apiBaseUrl, EnvConfig.defaultApiBaseUrl);
      expect(EnvConfig.hasCustomApiBaseUrl, isFalse);
    });
  });

  group('EnvConfig.geminiApiKey', () {
    test('menerima API key yang terisi', () {
      dotenv.testLoad(fileInput: 'GEMINI_API_KEY=AIza-fake-key-untuk-pengujian');

      expect(EnvConfig.geminiApiKey, 'AIza-fake-key-untuk-pengujian');
      expect(EnvConfig.hasGeminiApiKey, isTrue);
    });

    test('menolak placeholder bawaan .env.example', () {
      dotenv.testLoad(
        fileInput: 'GEMINI_API_KEY=${EnvConfig.geminiApiKeyPlaceholder}',
      );

      expect(EnvConfig.hasGeminiApiKey, isFalse);
      expect(EnvConfig.geminiApiKey, EnvConfig.geminiApiKeyPlaceholder);
    });

    test('menolak API key kosong', () {
      dotenv.testLoad(fileInput: 'GEMINI_API_KEY=');

      expect(EnvConfig.geminiApiKey, isEmpty);
      expect(EnvConfig.hasGeminiApiKey, isFalse);
    });

    test('menolak API key yang hanya berisi spasi', () {
      dotenv.testLoad(fileInput: 'GEMINI_API_KEY=    ');

      expect(EnvConfig.hasGeminiApiKey, isFalse);
    });
  });

  group('EnvConfig.geminiModel', () {
    test('membaca GEMINI_MODEL dari environment', () {
      dotenv.testLoad(fileInput: 'GEMINI_MODEL=gemini-lokal-uji');

      expect(EnvConfig.geminiModel, 'gemini-lokal-uji');
    });

    test('memakai model default ketika GEMINI_MODEL kosong', () {
      dotenv.testLoad(fileInput: 'GEMINI_MODEL=');

      expect(EnvConfig.geminiModel, EnvConfig.defaultGeminiModel);
    });
  });
}
