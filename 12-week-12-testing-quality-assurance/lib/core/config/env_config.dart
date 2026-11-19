import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi environment terpusat untuk aplikasi `campus_notification`.
///
/// Seluruh nilai yang bergantung pada environment — base URL API, API key
/// layanan AI, dan nama model AI — dibaca dari satu tempat, yaitu file `.env`
/// di root project. Dengan pendekatan ini tidak ada lagi credential atau URL
/// yang ditulis langsung (hardcode) di dalam source code.
///
/// Catatan keamanan: file `.env` pada aplikasi Flutter ikut terpaket dalam
/// artefak build sehingga tidak dapat dianggap sebagai tempat penyimpanan
/// rahasia yang aman. Credential yang benar-benar sensitif harus disimpan di
/// backend. API key di sini hanya dipakai untuk keperluan praktikum.
class EnvConfig {
  const EnvConfig._();

  /// Nama file environment default.
  static const String defaultEnvFile = '.env';

  /// Key environment untuk base URL API.
  static const String apiBaseUrlKey = 'API_BASE_URL';

  /// Key environment untuk API key Gemini.
  static const String geminiApiKeyKey = 'GEMINI_API_KEY';

  /// Key environment untuk nama model Gemini.
  static const String geminiModelKey = 'GEMINI_MODEL';

  /// Base URL cadangan bila `API_BASE_URL` belum diisi pada `.env`.
  static const String defaultApiBaseUrl = 'https://mock-api.example.com';

  /// Nama model Gemini cadangan bila `GEMINI_MODEL` belum diisi.
  static const String defaultGeminiModel = 'gemini-3.8-flash';

  /// Placeholder yang dipakai pada `.env.example`.
  /// Nilai ini dianggap sebagai "belum dikonfigurasi".
  static const String geminiApiKeyPlaceholder = 'YOUR_GEMINI_API_KEY_HERE';

  /// Memuat file `.env` ke dalam memori.
  ///
  /// Dipanggil sekali pada `main()` sebelum konfigurasi API digunakan. Melempar
  /// `Exception` bila file tidak ditemukan sehingga pemanggil dapat menangani
  /// kondisi tersebut secara eksplisit.
  static Future<void> load({String fileName = defaultEnvFile}) async {
    await dotenv.load(fileName: fileName);
  }

  /// Membaca nilai environment [key] yang sudah di-trim.
  ///
  /// Mengembalikan [fallback] bila dotenv belum dimuat, key tidak tersedia,
  /// nilainya kosong, atau hanya berisi spasi.
  static String? read(String key, {String? fallback}) {
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  /// Base URL API aktif, tanpa garis miring di akhir.
  static String get apiBaseUrl {
    final raw = read(apiBaseUrlKey, fallback: defaultApiBaseUrl)!;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// True bila `API_BASE_URL` diisi secara eksplisit pada `.env`.
  static bool get hasCustomApiBaseUrl => read(apiBaseUrlKey) != null;

  /// API key Gemini. String kosong berarti belum dikonfigurasi.
  static String get geminiApiKey => read(geminiApiKeyKey, fallback: '')!;

  /// Nama model Gemini yang dipakai aplikasi.
  static String get geminiModel =>
      read(geminiModelKey, fallback: defaultGeminiModel)!;

  /// True bila API key Gemini sudah diisi dan bukan placeholder.
  static bool get hasGeminiApiKey {
    final key = geminiApiKey;
    return key.isNotEmpty && key != geminiApiKeyPlaceholder;
  }
}
