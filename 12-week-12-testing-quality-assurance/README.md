# Jobsheet 12 — Testing & Quality Assurance

## Identitas Mahasiswa
- **Nama:** Rifqi Aries Saputra
- **NIM:** 244107020175
- **Kelas:** TI-3H

---

## Deskripsi & Tujuan Praktikum

Praktikum Jobsheet 12 menerapkan materi **Testing & Quality Assurance** pada project nyata `campus_notification` — aplikasi Flutter dengan arsitektur *Clean Architecture* dan state management *Riverpod* yang sudah dikembangkan sejak Jobsheet 1 hingga Jobsheet 11.

Fitur dan arsitektur aplikasi tidak diubah. Pekerjaan pada praktikum ini difokuskan pada:

1. Memusatkan seluruh konfigurasi API dan environment pada file `.env` melalui kelas `EnvConfig`.
2. Menulis **unit test** untuk logika bisnis nyata aplikasi (validasi login, pencarian pengumuman, pemetaan model, konfigurasi environment, serta fitur AI).
3. Menyediakan **fake repository** sebagai pengganti sumber data sehingga pengujian tidak membutuhkan jaringan maupun server.
4. Menulis **widget test** untuk halaman login, halaman utama, halaman detail pengumuman, dan halaman AI Assistant.
5. Menulis satu **integration test** untuk alur utama aplikasi (login → daftar pengumuman → pencarian → detail).
6. Menjalankan `flutter test`, `flutter test --coverage`, dan `flutter analyze`, lalu menganalisis hasil *code coverage*.

---

## 1. Analisis Project (Tahap 1)

### Struktur & Arsitektur

```
lib/
├── core/
│   ├── config/env_config.dart      # (baru) konfigurasi environment terpusat
│   ├── failures.dart               # hirarki Failure untuk domain
│   └── format.dart                 # helper murni (format & parsing)
├── features/
│   ├── announcements/              # data / domain / presentation
│   ├── auth/                       # data / domain / presentation
│   └── ai/                         # data / domain / presentation
├── firebase_options.dart
├── main.dart
├── routes.dart
└── services/notification_service.dart
```

Setiap fitur memakai pemisahan *Clean Architecture*:

| Lapisan | Isi | Ketergantungan |
|---|---|---|
| **Domain** | entity, kontrak repository, use case | murni Dart |
| **Data** | model, datasource, implementasi repository | Dio, FlutterSecureStorage, Gemini |
| **Presentation** | halaman, widget, provider Riverpod | Flutter |

Ketergantungan disuntikkan melalui Riverpod (`Provider`, `AsyncNotifierProvider`, `FutureProvider`), sehingga setiap lapisan dapat diganti dengan implementasi tiruan saat pengujian melalui `ProviderScope.overrides`.

### Objek pengujian yang dipilih

| Bagian aplikasi | Alasan dipilih |
|---|---|
| `LoginUseCase`, `CheckAuthStatusUseCase`, `LogoutUseCase` | aturan bisnis validasi kredensial dan sesi; mudah diuji tanpa UI |
| `SearchAnnouncements` | logika filter pencarian dengan banyak kasus tepi (kosong, spasi, huruf besar/kecil) |
| `GetAnnouncements`, `GetAnnouncementById` | kontrak use case terhadap repository |
| `AnnouncementRepositoryImpl` | cache *Stale-While-Revalidate* dan fallback data |
| `AnnouncementModel`, `AuthUserModel` | serialisasi JSON/Map dan pemetaan ke entity |
| `EnvConfig` | konfigurasi environment terpusat (baru pada JS 12) |
| `AIRepositoryImpl`, `AIRemoteDataSourceImpl` | penerjemahan error layanan AI dan mode simulasi tanpa API key |
| `LoginPage`, `HomePage`, `AnnouncementPage`, `AIChatPage` | halaman dengan state loading/error/kosong dan interaksi pengguna |

### Rencana implementasi

1. Membuat `lib/core/config/env_config.dart` sebagai satu-satunya pintu masuk konfigurasi.
2. Mengganti base URL dan API key yang sebelumnya ditulis langsung pada `ApiClient` dan `AIRemoteDataSourceImpl`.
3. Menambahkan `test/helpers/fakes.dart` berisi fake repository yang dapat dikendalikan pengujian.
4. Menambahkan unit test, widget test, dan `integration_test/app_test.dart`.
5. Menjalankan seluruh pemeriksaan mutu dan mendokumentasikan hasil aktual.

---

## 2. Pengelolaan Konfigurasi API dan Environment

### Sebelum JS 12

| Nilai | Lokasi lama | Masalah |
|---|---|---|
| `https://mock-api.example.com` | ditulis langsung di `ApiClient` | sulit diganti antar environment |
| `gemini-3.8-flash` | ditulis langsung di `AIRemoteDataSourceImpl` | nama model tidak dapat dikonfigurasi |
| API key Gemini | dibaca `dotenv.env[...]` tersebar di dua tempat | duplikasi logika validasi |

### Sesudah JS 12

Seluruh nilai dipusatkan pada `EnvConfig` (`lib/core/config/env_config.dart`):

```dart
EnvConfig.apiBaseUrl        // API_BASE_URL, default: https://mock-api.example.com
EnvConfig.geminiApiKey      // GEMINI_API_KEY
EnvConfig.geminiModel       // GEMINI_MODEL, default: gemini-3.8-flash
EnvConfig.hasGeminiApiKey   // false bila kosong atau masih placeholder
EnvConfig.hasCustomApiBaseUrl
```

- `EnvConfig.load()` dipanggil satu kali di `main()` sebelum konfigurasi digunakan.
- `ApiClient` menerima `baseUrl` opsional (`baseUrl ?? EnvConfig.apiBaseUrl`), sehingga pengujian dapat menyuntikkan URL tiruan.
- `AIRemoteDataSourceImpl` membaca API key dan nama model dari `EnvConfig`; nilai kosong atau `YOUR_GEMINI_API_KEY_HERE` diperlakukan sebagai "belum dikonfigurasi" dan aplikasi masuk ke *mode simulasi*.

### File environment

| File | Status | Isi |
|---|---|---|
| `.env` | tidak di-commit (`.gitignore`) | nilai nyata: `GEMINI_API_KEY`, `API_BASE_URL`, `GEMINI_MODEL` |
| `.env.example` | di-commit | template tanpa credential asli |

Verifikasi `.gitignore`:

```text
12-week-12-testing-quality-assurance/.gitignore:52:.env            → terabaikan
12-week-12-testing-quality-assurance/.gitignore:54:!.env.example   → tetap terlacak
12-week-12-testing-quality-assurance/.gitignore:34:/coverage/      → terabaikan
```

> **Catatan keamanan.** File `.env` pada aplikasi Flutter ikut terpaket dalam artefak build, sehingga tidak dapat diperlakukan sebagai penyimpanan rahasia yang aman. Credential yang benar-benar sensitif harus berada di backend. Konfigurasi Firebase (`firebase_options.dart`, `firebase.json`, `google-services.json`) tetap dipertahankan sesuai kebutuhan Firebase dan tidak dipindahkan ke `.env`.

---

## 3. Implementasi Unit Testing

Unit test ditulis dengan `flutter_test` menggunakan pola **Arrange – Act – Assert**, dikelompokkan dengan `group()`, dan dijalankan dengan `test()`.

| File | Jumlah | Cakupan pengujian |
|---|---|---|
| `test/env_config_test.dart` | 13 | pembacaan nilai env, trimming, default, deteksi placeholder, penghapusan garis miring akhir URL |
| `test/login_usecase_edge_cases_test.dart` | 6 | email/password kosong & spasi, pemangkasan input, penerusan sukses dan kegagalan |
| `test/announcement_repository_unit_test.dart` | 12 | use case dengan fake repository (sukses, kosong, failure, exception), cache `AnnouncementRepositoryImpl`, fallback ID tidak dikenal, pemetaan `AnnouncementModel` |
| `test/ai_repository_unit_test.dart` | 4 | `AIRepositoryImpl` menerjemahkan exception menjadi `AIFailure`, mode simulasi tanpa API key |
| `test/search_announcements_test.dart` | 11 | pencarian case-insensitive, trim, data kosong, tidak ada hasil, provider Riverpod |
| `test/auth_test.dart`, `test/auth_usecase_test.dart`, `test/announcement_usecase_test.dart`, `test/format_test.dart`, `test/ai_feature_test.dart`, `test/performance_optimization_test.dart`, `test/search_widget_test.dart` | 52 | pengujian dari praktikum sebelumnya yang tetap dipertahankan |

Contoh pola AAA (dari `test/login_usecase_edge_cases_test.dart`):

```dart
test('menolak email kosong tanpa memanggil repository', () async {
  // Arrange
  final repository = FakeAuthRepository();
  final useCase = LoginUseCase(repository);

  // Act
  final result = await useCase(email: '', password: '123456');

  // Assert
  expect(result.user, isNull);
  expect(result.failure, isA<AuthFailure>());
  expect(result.failure!.message, 'Email dan password tidak boleh kosong');
  expect(repository.loginCallCount, 0); // repository tidak boleh dipanggil
});
```

Kasus tepi yang diuji antara lain: string kosong, string berisi spasi saja, huruf besar/kecil, nilai batas (`maskToken` dengan token pendek), ID tidak valid, data kosong, serta kondisi kegagalan/exception.

---

## 4. Repository Abstraction dan Fake Repository

Kontrak repository sudah tersedia di lapisan domain (`AnnouncementRepository`, `AuthRepository`, `AIRepository`) dan implementasi nyata tetap dipakai aplikasi. Untuk pengujian, dibuat implementasi tiruan pada `test/helpers/fakes.dart`:

| Fake | Perilaku yang dapat dikendalikan |
|---|---|
| `FakeAnnouncementRepository` | daftar data, `failure`, `throwException`, `delay`, pencatatan jumlah pemanggilan dan ID terakhir |
| `FakeAuthRepository` | hasil login sukses/gagal, `loginGate` (Completer) untuk menguji loading, pencatatan email & password yang dikirim |
| `FakeTokenStore` | penyimpanan token in-memory tanpa `FlutterSecureStorage` asli |
| `FakeAIRepository` | teks balasan, `failure`, dan `gate` untuk menguji status loading |

Contoh penggunaan pada widget test:

```dart
ProviderScope(
  overrides: [
    tokenStoreProvider.overrideWithValue(FakeTokenStore()),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  ],
  child: const MaterialApp(home: LoginPage()),
);
```

Dengan cara ini unit test dan widget test **tidak membutuhkan internet, server, Firebase, maupun API key**, dan hasilnya konsisten karena data sepenuhnya dikendalikan pengujian.

---

## 5. Implementasi Widget Testing

Widget test ditulis dengan `testWidgets()` dan memakai `pumpWidget()`, `find.text()`, `find.byType()`, `find.byTooltip()`, `tester.enterText()`, `tester.tap()`, `pump()`, dan `pumpAndSettle()`.

| File | Jumlah | Skenario |
|---|---|---|
| `test/widget/login_page_widget_test.dart` | 5 | tampilan awal; validasi email kosong; validasi password kosong; indikator loading + tombol nonaktif; SnackBar saat kredensial salah |
| `test/widget/home_page_widget_test.dart` | 6 | state loading; state error; state data kosong; daftar pengumuman tampil; penyaringan saat mengetik + reset pencarian; aksi logout |
| `test/widget/announcement_page_widget_test.dart` | 3 | state loading; state error + tombol "Coba Lagi"; tampilan judul, tanggal, isi, dan chip |
| `test/widget/ai_chat_page_widget_test.dart` | 5 | empty state; kirim prompt & balasan AI; indikator loading; SnackBar saat layanan gagal; hapus percakapan |

Tidak ada `Future.delayed()` yang dipakai untuk "memaksa" pengujian lulus. Penundaan pada pengujian loading menggunakan `Completer` yang dikendalikan langsung oleh test.

---

## 6. Implementasi Integration Testing

File: `integration_test/app_test.dart` (paket `integration_test` ditambahkan pada `dev_dependencies`).

```dart
IntegrationTestWidgetsFlutterBinding.ensureInitialized();
app.main();                       // menjalankan aplikasi sungguhan
// login → daftar pengumuman → pencarian "Registrasi" → buka detail
```

Alur yang diuji:

1. Halaman login tampil (`Silakan login untuk melanjutkan`).
2. Login dengan kredensial demo aplikasi → halaman utama tampil (`Selamat datang!`, `Daftar Pengumuman Kampus`).
3. Daftar pengumuman termuat (`Registrasi Semester Baru`).
4. Pencarian `Registrasi` menyisakan satu pengumuman saja.
5. Mengetuk kartu membuka detail (`Pengumuman #1`, judul pengumuman).

Pengujian memakai helper `waitFor()` berbasis `pump()` bertahap (bukan `pumpAndSettle()`) agar tidak macet saat indikator loading berputar.

Perintah yang digunakan:

```bash
flutter test integration_test/app_test.dart -d <device_id>
```

**Status eksekusi:** belum dapat dijalankan pada mesin ini karena tidak tersedia perangkat target. Lihat bagian *Kendala*.

---

## 7. Daftar Skenario Pengujian (Rekapitulasi)

| # | Jenis | Skenario | Hasil |
|---|---|---|---|
| 1 | Unit | `EnvConfig` membaca nilai `.env` dan memangkas spasi | PASS |
| 2 | Unit | `EnvConfig` memakai default saat nilai kosong/tidak ada | PASS |
| 3 | Unit | Placeholder API key dianggap belum dikonfigurasi | PASS |
| 4 | Unit | Login menolak email/password kosong tanpa memanggil repository | PASS |
| 5 | Unit | Login memangkas spasi sebelum dikirim ke repository | PASS |
| 6 | Unit | Login meneruskan `AuthFailure` dari repository | PASS |
| 7 | Unit | Pencarian pengumuman case-insensitive pada judul dan isi | PASS |
| 8 | Unit | Pencarian mengembalikan seluruh data saat query kosong | PASS |
| 9 | Unit | Pencarian mengembalikan list kosong saat tidak ada kecocokan | PASS |
| 10 | Unit | Use case pengumuman meneruskan data kosong tanpa failure | PASS |
| 11 | Unit | Use case mengembalikan `NetworkFailure` saat repository gagal | PASS |
| 12 | Unit | `AnnouncementRepositoryImpl` memberi data fallback untuk ID tak dikenal | PASS |
| 13 | Unit | `AnnouncementModel` memberi nilai default untuk field tidak lengkap | PASS |
| 14 | Unit | `AIRepositoryImpl` mengubah exception menjadi `AIFailure` | PASS |
| 15 | Unit | AI datasource memakai mode simulasi tanpa API key | PASS |
| 16 | Widget | Halaman login menampilkan seluruh elemen utama | PASS |
| 17 | Widget | Validasi form email kosong menampilkan pesan error | PASS |
| 18 | Widget | Validasi form password kosong menampilkan pesan error | PASS |
| 19 | Widget | Tombol login menampilkan loading dan menjadi nonaktif | PASS |
| 20 | Widget | SnackBar tampil saat kredensial salah | PASS |
| 21 | Widget | Halaman utama menampilkan indikator loading | PASS |
| 22 | Widget | Halaman utama menampilkan pesan error | PASS |
| 23 | Widget | Halaman utama menampilkan state data kosong | PASS |
| 24 | Widget | Halaman utama menampilkan daftar pengumuman | PASS |
| 25 | Widget | Pencarian menyaring daftar dan reset mengembalikan data | PASS |
| 26 | Widget | Tombol logout memanggil use case logout | PASS |
| 27 | Widget | Halaman detail menampilkan loading, error + retry, dan data | PASS |
| 28 | Widget | Halaman AI menampilkan empty state, balasan, loading, error, dan hapus chat | PASS |
| 29 | Integration | Alur login → daftar → pencarian → detail | Belum dijalankan (tidak ada perangkat) |

---

## 8. Perintah Menjalankan Pengujian

```bash
# 1. Memasang dependensi
flutter pub get

# 2. Unit + widget test
flutter test

# 3. Unit + widget test beserta laporan coverage
flutter test --coverage

# 4. Analisis statis
flutter analyze

# 5. Integration test (butuh emulator/perangkat Android aktif)
flutter devices
flutter test integration_test/app_test.dart -d <device_id>
```

---

## 9. Hasil Eksekusi (Aktual)

### `flutter pub get`

```text
Changed 6 dependencies!
43 packages have newer versions incompatible with dependency constraints.
```

Dependensi baru berasal dari paket `integration_test` (`process`, `sync_http`, `webdriver`, dll.).

### `flutter test`

```text
00:06 +106: All tests passed!
```

Rincian: **85 unit test** dan **21 widget test**, seluruhnya lulus tanpa kegagalan.

### `flutter analyze`

```text
Analyzing 12-week-12-testing-quality-assurance...
No issues found! (ran in 2.6s)
```

### `flutter test --coverage`

```text
coverage/lcov.info dibuat — 29 file, 609 baris tereksekusi dari 793 baris
Total line coverage: 76.80%
```

### `flutter test integration_test/app_test.dart -d <device_id>`

Belum dijalankan. Rincian kendala pada bagian berikut.

### Kendala

| Kendala | Penyebab | Status |
|---|---|---|
| Integration test belum dieksekusi | Tidak ada emulator/perangkat Android aktif (`flutter devices` hanya menampilkan Windows, Chrome, Edge) | File test sudah ditulis dan lolos `flutter analyze`; perlu dijalankan pada perangkat |
| Integration test via web | Flutter menolak: `Web devices are not supported for integration tests yet.` | Perlu perangkat Android fisik/emulator |
| Integration test via Windows desktop | `Visual Studio` (workload *Desktop development with C++*) belum terpasang sehingga build desktop Windows tidak tersedia | Opsional, tidak dipakai untuk JS 12 |
| `flutter emulators` kosong | Belum ada AVD yang dibuat pada mesin ini | Dapat dibuat melalui Android Studio AVD Manager |

---

## 10. Analisis Code Coverage

### Apa fungsi code coverage?

Code coverage mengukur **seberapa banyak baris kode program yang ikut dieksekusi** ketika seluruh pengujian dijalankan. Laporan `lcov.info` membantu menemukan bagian kode yang belum pernah tersentuh pengujian sama sekali, sehingga pengembang tahu di mana pengujian masih perlu ditambah.

### Bagian yang sudah teruji dengan baik

| File | Coverage | Keterangan |
|---|---|---|
| `core/format.dart` | 100% | seluruh helper format/parsing |
| `features/announcements/domain/usecases/*` | 100% | ketiga use case pengumuman |
| `features/announcements/data/models/announcement_model.dart` | 100% | serialisasi & mapping |
| `features/auth/domain/usecases/*` | 100% | login, logout, cek status |
| `features/ai/domain/usecases/send_prompt_usecase.dart` | 100% | validasi prompt |
| `features/ai/presentation/widgets/chat_bubble.dart` | 100% | bubble percakapan |
| `features/auth/presentation/pages/login_page.dart` | 100% | halaman login |
| `features/ai/presentation/pages/ai_chat_page.dart` | 99.1% | halaman AI Assistant |
| `features/auth/presentation/pages/home_page.dart` | 91.8% | halaman utama |
| `features/announcements/data/repositories/announcement_repository_impl.dart` | 85.9% | cache & fallback |
| `core/config/env_config.dart` | 82.4% | konfigurasi environment |
| `features/announcements/presentation/pages/announcement_page.dart` | 82.6% | halaman detail |

### Bagian yang belum tercakup

| File | Coverage | Alasan |
|---|---|---|
| `features/auth/data/datasources/api_client.dart` | 0% | interceptor Dio membutuhkan server palsu/`DioAdapter`; memerlukan dependency tambahan yang tidak diminta modul |
| `features/auth/data/datasources/token_store.dart` | 9.1% | bergantung pada platform channel `FlutterSecureStorage`; perilakunya sudah diuji lewat `FakeTokenStore` |
| `features/auth/domain/entities/auth_user.dart` | 12.5% | hanya `operator ==`/`hashCode` yang belum tersentuh |
| `features/ai/domain/entities/ai_message.dart` | 14.3% | method `copyWith` belum dipakai pada pengujian |
| `features/ai/data/datasources/ai_remote_datasource.dart` | 22.7% | jalur yang memanggil Gemini API sungguhan sengaja tidak diuji (butuh jaringan dan API key asli) |
| `features/auth/data/models/auth_user_model.dart` | 28.6% | sebagian method `toMap`/`toEntity` belum dipakai pengujian |

### Bagaimana coverage membantu menemukan kekurangan pengujian?

Laporan per baris menunjukkan bahwa lapisan **domain** dan **presentation** sudah hampir penuh, sedangkan lapisan **data** yang bergantung pada platform (`ApiClient`, `FlutterSecureStorage`, Gemini) masih rendah. Informasi ini menjadi daftar kerja berikutnya: bila ingin menaikkan cakupan secara bermakna, pengujian harus memakai `DioAdapter`/mock HTTP dan abstraksi penyimpanan, bukan sekadar menambah assertion.

### Mengapa coverage tinggi tidak selalu menjamin kualitas?

Coverage menghitung **baris yang dieksekusi**, bukan **perilaku yang diperiksa**. Sebuah baris bisa tereksekusi tanpa satu pun `expect()` yang memverifikasi hasilnya. Contohnya, memanggil sebuah halaman akan menaikkan coverage, tetapi bila tidak ada assertion tentang isi layar, kesalahan tetap lolos. Karena itu pengujian di JS 12 selalu menyertakan assertion yang memeriksa hasil akhir (pesan error, jumlah widget, nilai balik use case), bukan hanya menjalankan kode.

---

## 11. Screenshot yang Perlu Dilampirkan

Simpan seluruh tangkapan layar pada folder `screenshots/` dengan nama berikut:

1. `js12-login-page.png` — halaman login saat aplikasi dijalankan.
2. `js12-home-announcements.png` — halaman utama beserta daftar pengumuman.
3. `js12-search-empty-state.png` — hasil pencarian kosong beserta tombol reset.
4. `js12-ai-chat.png` — halaman AI Assistant (empty state dan percakapan).
5. `js12-unit-widget-test.png` — keluaran `flutter test` (`All tests passed!`).
6. `js12-flutter-analyze.png` — keluaran `flutter analyze` (`No issues found!`).
7. `js12-coverage.png` — ringkasan coverage dari `coverage/lcov.info` atau tab *Testing* di IDE.
8. `js12-integration-test.png` — keluaran integration test pada perangkat/emulator (diambil setelah perangkat tersedia).

---

## 12. Refleksi Praktikum

### 1. Bug apa yang paling mungkin terlewat tanpa pengujian yang ditulis?

Bug yang paling mungkin terlewat adalah kesalahan pada **input tidak valid dan kondisi tepi**. Contohnya, `LoginUseCase` sebenarnya menolak email/password yang hanya berisi spasi, `SearchAnnouncements` mengabaikan spasi di awal dan akhir kata kunci, serta `maskToken` menyamarkan token pendek secara berbeda. Tanpa pengujian, perilaku ini mudah rusak saat kode diubah dan baru ketahuan ketika pengguna gagal login atau hasil pencarian terasa aneh. Selain itu, perubahan pada state loading/error di UI juga sulit diperiksa manual karena harus menunggu proses jaringan selesai.

### 2. Bagian mana yang perlu fake, dan bagaimana fake membuat pengujian lebih konsisten?

Bagian yang perlu fake adalah seluruh **sumber data eksternal**: repository pengumuman, repository autentikasi, penyimpanan token, dan layanan AI. Fake membuat pengujian konsisten karena data dan kegagalan sepenuhnya ditentukan oleh test, bukan oleh kondisi jaringan atau isi server. Hasil pengujian menjadi dapat diulang (deterministik), cepat karena tanpa jeda jaringan, dan aman karena tidak memakai credential asli. Fake juga memungkinkan pengujian skenario yang sulit dipicu pada aplikasi nyata, seperti daftar kosong, `NetworkFailure`, atau exception dari layanan AI.

### 3. Apa perbedaan nilai yang diberikan pengujian widget dan pengujian integrasi pada fitur project?

Pengujian widget memverifikasi **satu halaman secara terisolasi**: apakah elemen tampil, apakah pesan validasi muncul, dan bagaimana tampilan berubah setelah pengguna berinteraksi. Pengujian ini cepat dan presisi, tetapi tidak memeriksa hubungan antar halaman. Pengujian integrasi memverifikasi **alur utuh** dari login, pemuatan data, pencarian, hingga membuka detail, sehingga dapat menemukan masalah yang tidak terlihat pada pengujian widget, misalnya kesalahan konfigurasi router, inisialisasi `.env`/Firebase, atau penyimpanan token. Konsekuensinya, pengujian integrasi lebih lambat, membutuhkan perangkat, dan lebih rentan terhadap perbedaan kondisi lingkungan.

---

## 13. Kesimpulan

1. Konfigurasi API kini terpusat pada `EnvConfig` yang membaca `.env`, dengan template `.env.example` tanpa credential dan `.env` yang sudah diabaikan Git.
2. Terdapat **106 pengujian otomatis** (85 unit + 21 widget) yang seluruhnya lulus, ditambah 1 integration test untuk alur utama.
3. Seluruh unit test dan widget test berjalan tanpa jaringan, Firebase, maupun API key karena memakai fake repository melalui `ProviderScope.overrides`.
4. `flutter analyze` bersih tanpa issue, dan line coverage tercatat **76.80%** dengan lapisan domain/models mencapai 100%.
5. Integration test belum dieksekusi karena tidak tersedia perangkat target pada mesin ini; perintah dan skenarionya sudah disiapkan agar dapat dijalankan pada emulator Android.
6. Tidak ada fitur aplikasi yang diubah atau dihapus, dan tidak dilakukan `git commit`/`push`.

---

## 14. Rekomendasi Pesan Commit (Conventional Commits)

```text
test(js12): add unit, widget, and integration tests with centralized env config

- add EnvConfig to read API_BASE_URL, GEMINI_API_KEY, and GEMINI_MODEL from .env
- replace hardcoded base URL and Gemini model name with centralized config
- add .env.example template and keep .env ignored by git
- add fake repositories for announcements, auth, tokens, and AI in test helpers
- add unit tests for EnvConfig, login validation, announcement use cases, AI repository
- add widget tests for LoginPage, HomePage, AnnouncementPage, and AIChatPage
- add integration test covering login, announcement list, search, and detail flow
- document testing scenarios, results, coverage, and reflection in README
```

---

## Catatan Tambahan

- Folder `docs/` pada week ini masih memuat dokumentasi praktikum sebelumnya (arsitektur, laporan performa JS 11) yang tetap relevan sebagai rujukan; rincian teknis JS 12 ada pada `docs/testing-quality-assurance.md`.
- File `test/widget_test.dart` bawaan template Flutter (yang hanya berisi `main()` kosong tanpa pengujian) dihapus agar tidak ada test kosong yang menyesatkan. Seluruh pengujian nyata berada pada file-file yang tercantum pada bagian 3 dan 5.
