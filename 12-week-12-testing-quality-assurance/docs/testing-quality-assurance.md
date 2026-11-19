# Laporan Teknis Testing & Quality Assurance — Jobsheet 12

Dokumen ini melengkapi `README.md` dengan rincian teknis, perintah eksekusi, dan bukti hasil pengujian pada project `campus_notification`.

---

## 1. Ringkasan Perubahan Kode Aplikasi

| File | Jenis | Perubahan |
|---|---|---|
| `lib/core/config/env_config.dart` | baru | konfigurasi environment terpusat (baca `.env`, trim, default, deteksi placeholder, hapus garis miring akhir) |
| `lib/features/auth/data/datasources/api_client.dart` | diubah | `baseUrl` diambil dari `EnvConfig.apiBaseUrl` dan dapat disuntikkan melalui konstruktor |
| `lib/features/ai/data/datasources/ai_remote_datasource.dart` | diubah | API key dan nama model dibaca dari `EnvConfig`; logika placeholder tidak lagi diduplikasi |
| `lib/main.dart` | diubah | memuat environment melalui `EnvConfig.load()` |
| `pubspec.yaml` | diubah | deskripsi JS 12 dan `dev_dependencies: integration_test` |
| `.env.example` | diubah | template `API_BASE_URL`, `GEMINI_API_KEY`, `GEMINI_MODEL` |
| `.env` | diubah | penambahan `API_BASE_URL` dan `GEMINI_MODEL` (tidak di-commit) |

Tidak ada perubahan pada lapisan domain, alur bisnis, routing, Firebase, maupun tampilan aplikasi.

---

## 2. Inventaris Pengujian

### 2.1 Unit test (85 test)

| File | Jumlah | Fokus |
|---|---|---|
| `test/env_config_test.dart` | 13 | `EnvConfig.read`, `apiBaseUrl`, `geminiApiKey`, `geminiModel` |
| `test/login_usecase_edge_cases_test.dart` | 6 | validasi & penerusan `LoginUseCase` |
| `test/announcement_repository_unit_test.dart` | 12 | use case pengumuman + `AnnouncementRepositoryImpl` + `AnnouncementModel` |
| `test/ai_repository_unit_test.dart` | 4 | `AIRepositoryImpl`, mode simulasi `AIRemoteDataSourceImpl` |
| `test/search_announcements_test.dart` | 11 | pencarian & provider Riverpod |
| `test/auth_test.dart` | 18 | `TokenStore` (fake), `AuthRepositoryImpl`, payload notifikasi, route |
| `test/auth_usecase_test.dart` | 5 | login/logout/cek status dengan fake repository |
| `test/announcement_usecase_test.dart` | 4 | use case pengumuman dengan fake repository |
| `test/ai_feature_test.dart` | 6 | `SendPromptUseCase`, `AIChatNotifier` |
| `test/format_test.dart` | 4 | helper `core/format.dart` |
| `test/performance_optimization_test.dart` | 2 unit + 1 widget | cache repositori & pemetaan model gambar (JS 11) |

### 2.2 Widget test (21 test)

| File | Jumlah | Fokus |
|---|---|---|
| `test/widget/login_page_widget_test.dart` | 5 | tampilan awal, validasi form, loading, error |
| `test/widget/home_page_widget_test.dart` | 6 | loading, error, kosong, daftar, pencarian, logout |
| `test/widget/announcement_page_widget_test.dart` | 3 | loading, error + retry, data |
| `test/widget/ai_chat_page_widget_test.dart` | 5 | empty state, kirim prompt, loading, error, hapus chat |
| `test/search_widget_test.dart` | 1 | pencarian pada `HomePage` (JS 11) |

### 2.3 Integration test (1 test)

`integration_test/app_test.dart` — alur login → daftar pengumuman → pencarian → detail.

---

## 3. Strategi Fake & Override Provider

```dart
// Unit test: use case menerima fake repository lewat konstruktor.
final useCase = LoginUseCase(FakeAuthRepository());

// Widget test: dependensi diganti lewat ProviderScope.
ProviderScope(
  overrides: [
    tokenStoreProvider.overrideWithValue(FakeTokenStore()),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    announcementsListProvider.overrideWith((ref) => Future.value(items)),
    announcementDetailProvider.overrideWith((ref, id) => Future.value(item)),
    sendPromptUseCaseProvider.overrideWith(
      (ref) => SendPromptUseCase(FakeAIRepository()),
    ),
  ],
  child: const MaterialApp(home: HomePage()),
);
```

Catatan penting saat menulis widget test pada project ini:

1. `authProvider` adalah `AsyncNotifierProvider`; pada frame pertama statusnya masih `AsyncLoading` sehingga tombol login tampil sebagai indikator loading. Widget test harus memanggil `pumpAndSettle()` setelah `pumpWidget()` sebelum mengetuk tombol.
2. `pumpAndSettle()` tidak dapat dipakai saat `CircularProgressIndicator` sedang berputar (animasi terus terjadwal). Pengujian state loading memakai `pump()` dan `Completer` untuk mengendalikan penyelesaian future.
3. Untuk memicu state loading pada halaman, gunakan `Completer` pada override provider, bukan `Future.delayed()`.
4. `HomePage` memakai `CachedNetworkImage`; data pengujian memakai `imageUrl: null` agar tidak ada permintaan gambar jaringan.

---

## 4. Perintah dan Hasil Eksekusi

### 4.1 `flutter pub get`

```text
Resolving dependencies...
Changed 6 dependencies!
43 packages have newer versions incompatible with dependency constraints.
```

### 4.2 `flutter analyze`

```text
Analyzing 12-week-12-testing-quality-assurance...
No issues found! (ran in 2.6s)
```

### 4.3 `flutter test`

```text
00:06 +106: All tests passed!
```

### 4.4 `flutter test --coverage`

```text
00:06 +106: All tests passed!
Total line coverage: 609/793 = 76.80% (29 file)
```

### 4.5 `flutter test integration_test/app_test.dart -d <device_id>`

Belum dieksekusi: tidak ada perangkat Android/emulator aktif pada mesin pengujian.

```text
$ flutter devices
Found 3 connected devices:
  Windows (desktop) • windows • windows-x64
  Chrome (web)      • chrome  • web-javascript
  Edge (web)        • edge    • web-javascript

$ flutter test integration_test/app_test.dart -d chrome
Web devices are not supported for integration tests yet.
```

`flutter doctor` juga melaporkan `Visual Studio` belum terpasang, sehingga target desktop Windows tidak dapat dibangun.

---

## 5. Rincian Coverage per File

| File | Baris tereksekusi | Coverage |
|---|---|---|
| `lib/core/format.dart` | 13/13 | 100.0% |
| `lib/core/failures.dart` | 6/9 | 66.7% |
| `lib/core/config/env_config.dart` | 14/17 | 82.4% |
| `features/announcements/domain/usecases/get_announcements.dart` | 3/3 | 100.0% |
| `features/announcements/domain/usecases/get_announcement_by_id.dart` | 6/6 | 100.0% |
| `features/announcements/domain/usecases/search_announcements.dart` | 8/8 | 100.0% |
| `features/announcements/domain/entities/announcement.dart` | 9/15 | 60.0% |
| `features/announcements/data/models/announcement_model.dart` | 20/20 | 100.0% |
| `features/announcements/data/repositories/announcement_repository_impl.dart` | 55/64 | 85.9% |
| `features/announcements/presentation/providers/announcement_providers.dart` | 10/22 | 45.5% |
| `features/announcements/presentation/pages/announcement_page.dart` | 38/46 | 82.6% |
| `features/auth/domain/usecases/login_usecase.dart` | 6/6 | 100.0% |
| `features/auth/domain/usecases/logout_usecase.dart` | 3/3 | 100.0% |
| `features/auth/domain/usecases/check_auth_status_usecase.dart` | 3/3 | 100.0% |
| `features/auth/domain/entities/auth_user.dart` | 1/8 | 12.5% |
| `features/auth/data/models/auth_user_model.dart` | 2/7 | 28.6% |
| `features/auth/data/repositories/auth_repository_impl.dart` | 29/33 | 87.9% |
| `features/auth/data/datasources/token_store.dart` | 1/11 | 9.1% |
| `features/auth/data/datasources/api_client.dart` | 0/65 | 0.0% |
| `features/auth/presentation/providers/auth_providers.dart` | 22/32 | 68.8% |
| `features/auth/presentation/pages/login_page.dart` | 40/40 | 100.0% |
| `features/auth/presentation/pages/home_page.dart` | 134/146 | 91.8% |
| `features/ai/domain/entities/ai_message.dart` | 1/7 | 14.3% |
| `features/ai/domain/usecases/send_prompt_usecase.dart` | 5/5 | 100.0% |
| `features/ai/data/datasources/ai_remote_datasource.dart` | 5/22 | 22.7% |
| `features/ai/data/repositories/ai_repository_impl.dart` | 7/7 | 100.0% |
| `features/ai/presentation/providers/ai_providers.dart` | 24/30 | 80.0% |
| `features/ai/presentation/pages/ai_chat_page.dart` | 106/107 | 99.1% |
| `features/ai/presentation/widgets/chat_bubble.dart` | 38/38 | 100.0% |

Angka di atas diambil dari `coverage/lcov.info` hasil eksekusi nyata (`flutter test --coverage`).

---

## 6. Langkah Menjalankan Integration Test

1. Pastikan Android SDK dan lisensi sudah diterima:
   ```bash
   flutter doctor --android-licenses
   ```
2. Buat dan jalankan emulator:
   ```bash
   flutter emulators --create --name pixel_api36
   flutter emulators --launch pixel_api36
   flutter devices           # pastikan emulator terdeteksi
   ```
3. Salin `.env.example` menjadi `.env` (tidak wajib untuk alur ini; aplikasi tetap berjalan tanpa API key AI karena ada mode simulasi).
4. Jalankan pengujian:
   ```bash
   flutter test integration_test/app_test.dart -d emulator-5554
   ```
5. Ambil tangkapan layar keluaran terminal sebagai `screenshots/js12-integration-test.png`.

Jika emulator belum tersedia, alternatifnya memakai perangkat Android fisik dengan mode *USB debugging* aktif.

---

## 7. Temuan dan Catatan

1. **Duplikasi konfigurasi hilang.** Sebelumnya pemeriksaan placeholder API key ditulis dua kali (di `_getModel()` dan `generateTextResponse()`); kini keduanya memakai `EnvConfig.hasGeminiApiKey`.
2. **Password form default masih terisi.** `LoginPage` mengisi kredensial demo secara otomatis; ini perilaku bawaan praktikum sebelumnya dan tidak diubah agar alur demo tetap berjalan. Catatan ini relevan untuk pengembangan produksi.
3. **`api_client.dart` belum teruji langsung.** Interceptor Dio membutuhkan HTTP adapter tiruan (mis. `http_mock_adapter`) yang bukan bagian dari materi JS 12 sehingga tidak ditambahkan. Pengujian perilaku sesi dilakukan pada tingkat repository dan use case.
4. **Tidak ada test yang dilewati atau sengaja digagalkan.** Seluruh 106 test berjalan dan lulus; tidak ada assertion kosong.
5. **Tidak ada ketergantungan jaringan pada unit/widget test.** Semua sumber data eksternal diganti fake; hanya integration test yang memakai implementasi nyata.
