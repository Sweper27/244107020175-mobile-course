# AI Prompt Challenge — Jobsheet 7: Clean Architecture

Dokumen ini mencatat interaksi dengan AI Coding Assistant, perbandingan usulan arsitektur awal versus keputusan final, serta justifikasi teknis dan analisis trade-off sesuai panduan modul praktikum.

---

## 1. Prompt AI yang Digunakan

Berikut adalah prompt resmi yang diajukan ke AI Coding Assistant:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, services},
repository tercampur dengan implementasi, widget memanggil Dio langsung / data mock di UI.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Ringkasan Usulan Awal AI

AI mengusulkan:
1. Pemisahan menyeluruh ke dalam struktur **feature-first**: `lib/features/auth` dan `lib/features/announcements`.
2. Pembuatan tiga layer lengkap pada masing-masing fitur: `domain`, `data`, dan `presentation`.
3. Pembuatan class UseCase granular untuk setiap method repository:
   - `LoginUseCase`
   - `LogoutUseCase`
   - `CheckAuthStatusUseCase`
   - `RefreshTokenUseCase`
   - `GetAnnouncementByIdUseCase`
   - `GetAnnouncementsUseCase`
4. Penggunaan package fungsional eksternal seperti `fpdart` atau `dartz` (`Either<Failure, T>`) untuk membungkus hasil operasi domain.
5. Pembuatan class Service Locator manual via `get_it` di samping Riverpod.

---

## 3. Tabel Usulan Awal vs Keputusan Final

| Komponen / Masalah | Usulan Awal AI | Keputusan Final Mahasiswa | Alasan Teknis & Trade-off |
| :--- | :--- | :--- | :--- |
| **Pola Error Handling** | Menggunakan library eksternal `fpdart` (`Either<Failure, T>`). | Menggunakan **Dart Records murni** bertipe `({T? data, Failure? failure})`. | Menghindari dependensi pihak ketiga baru (`pubspec.yaml` tetap ramping), sintaks bawaan Dart 3 lebih bersih dan mudah dipahami mahasiswa. |
| **Granularitas Use Case** | Membuat use case terpisah untuk setiap method, termasuk `RefreshTokenUseCase` satu baris. | Menyederhanakan `RefreshToken` langsung ditangani di batas data / interceptor HTTP, sedangkan use case difokuskan pada operasi utama: `LoginUseCase`, `LogoutUseCase`, `CheckAuthStatusUseCase`, `GetAnnouncementById`, dan `GetAnnouncements`. | Membuat use case terpisah untuk refresh token yang hanya berupa delegasi satu baris ke repository adalah **over-engineering** (boilerplate tanpa nilai bisnis). Use case utama yang butuh validasi atau orkestrasi tetap dibuat. |
| **Dependency Injection** | Menggunakan `get_it` + `Injectable` bersamaan dengan Riverpod. | **Murni Riverpod Provider** (`Provider<Repo>`, `Provider<UseCase>`, `AsyncNotifier`). | Menolak dependensi ganda. Riverpod sudah merupakan container DI hierarkis yang reaktif, mendukung scoping, dan sangat mudah di-override saat testing menggunakan `ProviderContainer(overrides: [...])`. |
| **Letak Interface Repository** | Sempat disarankan digabung di `data/repositories/` dengan nama `auth_repository.dart`. | **Dipisahkan tegas**: Interface di `domain/repositories/`, implementasi konkrit di `data/repositories/`. | Aturan dependensi wajib: Domain adalah inti bisnis dan tidak boleh mengimpor layer Data. Pemisahan ini memungkinkan Domain diuji murni tanpa ketergantungan pada SQLite, Dio, atau secure storage. |
| **Mapping JSON & SQLite** | Diletakkan di dalam Entity agar praktis. | **Entity murni Dart tanpa `toMap`/`fromJson`**. Seluruh mapping ditempatkan di `data/models/`. | Mencegah kebocoran struktur data luar (skema JSON backend / database) ke dalam domain core logic. |
| **Integrasi Firebase Messaging** | Memindahkan FCM ke dalam domain sebagai UseCase. | FCM tetap diisolasi di `lib/services/` dan dipanggil di Presentation (`main.dart`), tanpa mengontaminasi Domain. | Domain harus steril dari SDK Flutter dan vendor luar seperti Firebase. Notifikasi adalah concern infrastruktur/presentasi sistem operasi. |

---

## 4. Alasan Teknis & Analisis Kapan Use Case Dibutuhkan

### Kapan Use Case Benar-Benar Dibutuhkan?
1. **Validasi & Business Rules**: Ketika ada aturan bisnis sebelum mengakses sumber data (misalnya validasi format email, sanitasi string ID, pemeriksaan kredensial kosong).
2. **Orkestrasi Multi-Repository**: Ketika satu tindakan pengguna memerlukan koordinasi data dari beberapa repository (misal: ambil profil pengguna lalu sinkronkan dengan data catatan offline).
3. **Caching & Policy Logic**: Memutuskan apakah harus mengambil dari cache lokal atau query jaringan.

### Kapan Repository Langsung ke Notifier Cukup?
1. Operasi CRUD sederhana satu baris (misal: query data tanpa transformasi atau parameter kompleks).
2. Menghindari layer passthrough tanpa logika (*boilerplate bloat*): membuat file 5 baris hanya untuk meneruskan argumen ke repository tanpa transformasi apa pun menambah beban pemeliharaan pada tim kecil.

---

## 5. Wiring Dependency Injection dengan Riverpod

Seluruh dependensi disuntikkan secara terarah melalui Provider Riverpod tanpa dependensi eksternal:

```dart
// 1. Data Layer: Data Source & Concrete Repository
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(tokenStore: ref.watch(tokenStoreProvider));
});

// 2. Domain Layer: Use Case menerima kontrak abstraksi
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// 3. Presentation Layer: State Notifier hanya memanggil Use Case
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);
```

Dengan pola ini, saat pengujian unit test UI maupun use case, kita dapat meng-override provider repository menggunakan fake repository dengan sangat bersih.
