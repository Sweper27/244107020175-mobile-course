# Jobsheet 7 — Clean Architecture

Laporan Praktikum Pemrograman Mobile: Implementasi Arsitektur Bersih (*Clean Architecture*) dengan Pendekatan *Feature-First* pada Flutter.

---

## 1. Identitas Mahasiswa

| Informasi | Keterangan |
| :--- | :--- |
| **Nama** | Rifqi Aries Saputra |
| **NIM** | 244107020175 |
| **Kelas** | TI-3H |
| **Program Studi** | D-IV Teknik Informatika |
| **Mata Kuliah** | Pemrograman Mobile |
| **Repositori** | `244107020175-mobile-course` |

---

## 2. Tujuan Praktikum

Setelah menyelesaikan praktikum ini, mahasiswa mampu:
1. Menjelaskan prinsip SOLID dan *Separation of Concerns* (SoC) dalam kode Flutter.
2. Membedakan struktur *Feature-First* vs *Layer-First* beserta analisis *trade-off*-nya.
3. Menerapkan tiga layer (*Presentation*, *Domain*, *Data*) dan mematuhi *Dependency Rules* (dependensi hanya mengarah ke dalam).
4. Membedakan peran *Entity* bisnis murni vs *Data Model* serta memisahkan *Repository Interface* di Domain dari implementasinya di Data.
5. Merancang *Use Case* untuk operasi bisnis utama dan mengelola *Dependency Injection* terpusat menggunakan Riverpod.
6. Menguji logika bisnis (*Domain Use Case*) secara independen menggunakan *Fake Repository* tanpa jaringan, database, atau Firebase sungguhan.

---

## 3. Deskripsi Project Awal & Fitur yang Dipertahankan

Praktikum ini melanjutkan project **Minggu 6 (`campus_notification`)** yang telah mengintegrasikan autentikasi, token secure storage, Firebase Cloud Messaging (FCM), dan navigasi detail pengumuman.

### Fitur Nyata yang Dipertahankan 100%:
1. **Autentikasi (Mock Service & Secure Storage)**:
   - Login dengan kredensial (`mahasiswa@kampus.ac.id` / `123456`).
   - Penyimpanan `access_token` dan `refresh_token` di `FlutterSecureStorage` (Keychain / Keystore).
   - Mekanisme logout yang membersihkan sesi dan token tersimpan.
2. **Navigasi & Route Guards (GoRouter)**:
   - Rute dilindungi (*guard*): redirect otomatis ke `/login` jika user belum login, dan redirect ke `/` (beranda) saat berhasil login.
   - Deep linking dan rute detail `/pengumuman/:id`.
3. **Pengumuman Kampus (Announcements)**:
   - Akses detail pengumuman berdasarkan ID pengumuman.
4. **Firebase Cloud Messaging (FCM) & Notifikasi Lokal**:
   - Integrasi Firebase background/foreground messaging dan local notifications tetap utuh dan aktif di `lib/services/notification_service.dart`.

---

## 4. Struktur Folder Akhir (Feature-First)

Struktur kode diatur dengan pendekatan **Feature-First**:

```text
lib/
├── core/
│   ├── failures.dart                                # Hierarki Failure murni Dart
│   └── format.dart                                  # Fungsi murni formatting & parsing
├── features/
│   ├── announcements/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── announcement_model.dart          # Serialisasi & mapping toEntity()
│   │   │   └── repositories/
│   │   │       └── announcement_repository_impl.dart# Implementasi repository data
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── announcement.dart                # Objek bisnis murni tanpa toMap/toJson
│   │   │   ├── repositories/
│   │   │   │   └── announcement_repository.dart     # Interface / kontrak repository
│   │   │   └── usecases/
│   │   │       ├── get_announcement_by_id.dart      # Use case detail pengumuman
│   │   │       └── get_announcements.dart           # Use case daftar pengumuman
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── announcement_page.dart           # Halaman detail UI
│   │       └── providers/
│   │           └── announcement_providers.dart      # DI Riverpod & UI State providers
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── api_client.dart                  # Dio + interceptor refresh token
│       │   │   └── token_store.dart                 # Wrapper FlutterSecureStorage
│       │   ├── models/
│       │   │   └── auth_user_model.dart             # Model data + toEntity()
│       │   └── repositories/
│       │       └── auth_repository_impl.dart        # Implementasi AuthRepository
│       ├── domain/
│       │   ├── entities/
│       │   │   └── auth_user.dart                   # Entity user murni Dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart             # Interface / kontrak autentikasi
│       │   └── usecases/
│       │       ├── check_auth_status_usecase.dart   # Use case verifikasi sesi aktif
│       │       ├── login_usecase.dart               # Use case validasi & login
│       │       └── logout_usecase.dart              # Use case pembersihan sesi
│       └── presentation/
│           ├── pages/
│           │   ├── home_page.dart                   # Halaman beranda
│           │   └── login_page.dart                  # Halaman login
│           └── providers/
│               └── auth_providers.dart              # DI Riverpod & AuthNotifier
├── services/
│   └── notification_service.dart                    # FCM & Local Notification handler
├── firebase_options.dart                            # Konfigurasi platform Firebase
├── routes.dart                                      # GoRouter config & auth redirect
└── main.dart                                        # Entrypoint aplikasi
```

---

## 5. Diagram Tiga Layer dan Arah Dependensi

```text
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│     (Pages / Widgets, Riverpod Notifiers, State, UI)       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ bergantung ke (imports)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        DOMAIN LAYER                         │
│  (Pure Dart Entities, Repository Interfaces, Use Cases,     │
│                    Domain Failures)                         │
└──────────────────────────────▲──────────────────────────────┘
                               │
                               │ diimplementasikan oleh (implements)
                               │
┌──────────────────────────────┴──────────────────────────────┐
│                         DATA LAYER                          │
│   (Data Models, JSON/Storage Mapping, Repository Impl,      │
│            TokenStore, ApiClient, Data Sources)             │
└─────────────────────────────────────────────────────────────┘
```

### Aturan Dependensi (*Dependency Rules*):
1. **Dependensi Mengarah ke Dalam**: Presentation bergantung pada Domain; Data mengimplementasikan kontrak Domain.
2. **Domain Steril Framework**: Tidak ada import `package:flutter`, `dio`, `sqflite`, atau `firebase` di dalam Domain. Logika bisnis dapat diuji secara independen.
3. **Data Mapping di Batas Data**: Entity murni tidak mengenal serialisasi JSON/SQLite. Konversi `toEntity()` dilakukan di dalam Model pada layer Data.
4. **Error Handling Terpadu**: Exception teknis dibungkus menjadi objek `Failure` (misal `AuthFailure`, `NotFoundFailure`) sebelum mencapai UI, sehingga UI hanya menerima pesan ramah pengguna.

---

## 6. Penjelasan Komponen Arsitektur

| Komponen | Layer | Peran dalam Project |
| :--- | :--- | :--- |
| **Entity** (`AuthUser`, `Announcement`) | Domain | Objek data bisnis murni. Tidak memiliki method serialisasi `toMap/fromMap/toJson/fromJson` dan tidak mengimpor package luar. |
| **Model** (`AuthUserModel`, `AnnouncementModel`) | Data | Representasi data luar/sumber data (JSON/Map/Database) yang mewarisi entity dan menyediakan fungsi pemetaan (`fromMap`, `toMap`, `toEntity()`). |
| **Repository Interface** (`AuthRepository`, `AnnouncementRepository`) | Domain | Kontrak abstrak murni yang mendefinisikan operasi data yang dibutuhkan domain tanpa peduli teknologi penyimpanan. |
| **Repository Implementation** (`AuthRepositoryImpl`, `AnnouncementRepositoryImpl`) | Data | Implementasi teknis dari repository interface menggunakan library seperti Dio, Secure Storage, atau in-memory source. |
| **Use Case** (`LoginUseCase`, `GetAnnouncementById`, dll.) | Domain | Kelas operasi bisnis spesifik yang memvalidasi input dan mengoordinasikan interaksi repository. |
| **Dependency Injection** (`auth_providers.dart`, `announcement_providers.dart`) | Presentation | Manajemen dependensi menggunakan provider Riverpod, menyuntikkan repository ke use case dan use case ke state notifier. |

---

## 7. Fitur yang Berhasil Direfactor

1. **Fitur Autentikasi (`features/auth/`)**:
   - Pemisahan `AuthRepository` interface (Domain) dan `AuthRepositoryImpl` (Data).
   - Pembuatan entity `AuthUser` dan model `AuthUserModel`.
   - Pembuatan use case: `LoginUseCase`, `LogoutUseCase`, dan `CheckAuthStatusUseCase`.
   - `AuthNotifier` diatur hanya memanggil Use Case.
2. **Fitur Pengumuman (`features/announcements/`)**:
   - Pemisahan data mock yang sebelumnya *hardcoded* di widget ke `AnnouncementRepositoryImpl`.
   - Pembuatan entity `Announcement` dan model `AnnouncementModel`.
   - Pembuatan use case: `GetAnnouncementById` dan `GetAnnouncements`.
   - UI `AnnouncementPage` diubah menjadi `ConsumerWidget` murni yang membaca provider.
3. **Core Utility (`core/`)**:
   - Ekstraksi formatting ID/chip dan sanitasi rute ke `lib/core/format.dart` sebagai fungsi murni yang dapat diuji.
   - Pembuatan hierarki error di `lib/core/failures.dart`.

---

## 8. Cara Menjalankan Aplikasi & Pengujian

### Prasyarat
- Flutter SDK (>= 3.13.1)
- Emulator Android / Perangkat Fisik / Chrome

### 1. Menjalankan Aplikasi
Masuk ke direktori project:
```bash
cd 07-week-7-clean-architecture
flutter pub get
flutter run
```

### 2. Menjalankan Static Analysis
```bash
flutter analyze
```
*Hasil: `No issues found!`*

### 3. Menjalankan Unit Tests
```bash
flutter test
```
*Hasil: `All 31 tests passed!`*

---

## 9. Tabel Hasil Pengujian Unit Test

Seluruh 31 pengujian unit test berjalan sukses tanpa kegagalan:

| Berkas Pengujian | Skenario Pengujian | Hasil | Keterangan |
| :--- | :--- | :---: | :--- |
| `test/announcement_usecase_test.dart` | 1. Skenario Sukses: Mengembalikan announcement dari fake repository | **LULUS** | Use case mengembalikan data entity dengan benar |
| `test/announcement_usecase_test.dart` | 2. Skenario Gagal: Mengembalikan Failure tanpa kebocoran exception | **LULUS** | Exception jaringan ditangkap menjadi `NetworkFailure` |
| `test/announcement_usecase_test.dart` | 3. Skenario Gagal: Validasi input kosong menghasilkan `NotFoundFailure` | **LULUS** | Input tidak valid dicegat di domain layer |
| `test/announcement_usecase_test.dart` | 4. Skenario Sukses: Mengembalikan seluruh daftar pengumuman | **LULUS** | Menampilkan list pengumuman |
| `test/auth_usecase_test.dart` | 1. Skenario Sukses: Login berhasil mengembalikan `AuthUser` | **LULUS** | Kredensial valid menghasilkan entity pengguna |
| `test/auth_usecase_test.dart` | 2. Skenario Gagal: Login salah mengembalikan `AuthFailure` | **LULUS** | Menghasilkan failure ramah pengguna |
| `test/auth_usecase_test.dart` | 3. Skenario Gagal: Validasi email/password kosong dicegat di UseCase | **LULUS** | Mencegah panggilan repository yang tidak perlu |
| `test/auth_usecase_test.dart` | 4. Skenario Sukses: LogoutUseCase mengembalikan `success=true` | **LULUS** | Sesi dihapus dengan benar |
| `test/auth_usecase_test.dart` | 5. Skenario Sukses: CheckAuthStatusUseCase memeriksa status aktif | **LULUS** | Mengembalikan status boolean aktif |
| `test/format_test.dart` | 1. `formatAnnouncementChip` memformat string chip dengan benar | **LULUS** | Pure function testing |
| `test/format_test.dart` | 2. `parseAnnouncementId` parsing ID default jika null/kosong | **LULUS** | Pure function testing |
| `test/format_test.dart` | 3. `isValidEmail` memvalidasi pola email | **LULUS** | Regex test |
| `test/format_test.dart` | 4. `maskToken` menyamarkan token secara aman | **LULUS** | Keamanan log token |
| `test/auth_test.dart` | Pengujian TokenStore (1–4: save, read, clear) | **LULUS** | Regresi token store data layer |
| `test/auth_test.dart` | Pengujian AuthRepositoryImpl (5–13: login, logout, refresh, isLoggedIn) | **LULUS** | Regresi repository implementasi |
| `test/auth_test.dart` | Pengujian Payload Notifikasi & Routing (14–18) | **LULUS** | Regresi router dan payload FCM |

---

## 10. Hasil Verifikasi Dependency Rule (Sterility Grep Checks)

| Parameter Pemeriksaan | Target | Perintah PowerShell | Hasil Aktual | Status |
| :--- | :---: | :--- | :---: | :---: |
| **Presentation Steril dari Data Mentah** | 0 temuan | `Get-ChildItem -Path "lib/features/*/presentation/pages" -Recurse -Include *.dart \| Select-String -Pattern "Dio\(\|openDatabase\|FlutterSecureStorage\|jsonDecode"` | **0 hasil** | **LOLOS** |
| **Domain Steril dari Framework** | 0 temuan | `Get-ChildItem -Path "lib/features/*/domain", "lib/core" -Recurse -Include *.dart \| Select-String -Pattern "import 'package:flutter\|import 'package:dio\|import 'package:sqflite\|import 'package:firebase"` | **0 hasil** | **LOLOS** |
| **Entity Bebas dari Serialisasi** | 0 temuan | `Get-ChildItem -Path "lib/features/*/domain/entities" -Recurse -Include *.dart \| Select-String -Pattern "toMap\|fromMap\|toJson\|fromJson"` | **0 hasil** | **LOLOS** |
| **Widget Bebas Instansiasi Manual** | 0 temuan | `Get-ChildItem -Path "lib/features/*/presentation/pages" -Recurse -Include *.dart \| Select-String -Pattern "AuthRepositoryImpl\(\|AnnouncementRepositoryImpl\("` | **0 hasil** | **LOLOS** |

---

## 11. Daftar Screenshot yang Perlu Diambil

Daftar file screenshot yang didokumentasikan di folder `Screenshots/`:

1. `Login.jpeg`: Tampilan UI login sebelum refactor (tersedia).
2. `home.jpeg`: Tampilan UI home setelah login sebelum refactor (tersedia).
3. `pengumuman.jpeg`: Tampilan UI detail pengumuman sebelum refactor (tersedia).
4. `notifikasi.jpeg`: Notifikasi di notification drawer OS sebelum refactor (tersedia).
5. `after-login.png`: Tampilan UI login setelah Clean Architecture.
6. `after-home.png`: Tampilan UI home setelah Clean Architecture.
7. `after-announcement.png`: Tampilan UI detail pengumuman setelah Clean Architecture.
8. `architecture-folders.png`: Struktur folder explorer VS Code memperlihatkan `core/` dan `features/`.
9. `analyze-results.png`: Tangkapan layar terminal `flutter analyze` (No issues found).
10. `test-results.png`: Tangkapan layar terminal `flutter test` (All 31 tests passed).

---

## 12. Kesimpulan dan Refleksi

### 1. Mengapa interface repository harus tinggal di domain, bukan di data? Apa yang rusak bila dibalik?
Interface repository adalah kontrak kebutuhan bisnis aplikasi. Bila interface ditaruh di layer Data, maka Domain harus mengimpor layer Data untuk membaca kontrak tersebut. Hal ini melanggar *Dependency Inversion Principle* (DIP) dan *Dependency Rule*, di mana dependensi berbalik keluar. Akibatnya:
- Domain menjadi terikat secara langsung pada implementasi teknologi luar.
- Unit testing pada logika bisnis menjadi sulit karena domain tidak dapat berdiri sendiri tanpa layer data.
- Mengganti datasource (misalnya dari SQLite lokal ke REST API atau GraphQL) berpotensi merusak domain logic.

### 2. Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?
- **Use Case dibutuhkan ketika**:
  1. Terdapat validasi aturan bisnis sebelum atau sesudah data diambil (misal: sanitasi string ID, validasi kredensial kosong, pemfilteran status).
  2. Operasi melibatkan koordinasi dari beberapa repository (orkestrasi multi-sumber data).
  3. Terdapat logika bisnis seperti *caching policy*, sinkronisasi offline, atau pencatatan analitik transaksi.
- **Repository langsung ke Notifier sudah cukup ketika**:
  Operasi hanya berupa operasi CRUD satu baris sederhana (misal sekadar `repo.getAll()`) tanpa ada transformasi atau logika bisnis tambahan. Melewatkan use case pada kasus ini mencegah timbulnya *boilerplate pass-through class* yang tidak memiliki nilai fungsional.

### 3. Apa biaya over-engineering (use case per CRUD satu-baris) bagi tim kecil? Kapan biayanya sepadan?
- **Biaya Over-Engineering**:
  Mengharuskan tim kecil membuat 4 file berbeda (Entity, UseCase, Repository Interface, Repository Impl) untuk operasi baca satu baris menambah kompleksitas navigasi file, meningkatkan *cognitive load*, dan memperlambat kecepatan pengembangan (*time-to-market*).
- **Kapan Biayanya Sepadan**:
  Biaya tersebut sepadan saat aplikasi dikerjakan oleh tim lintas divisi yang besar, di mana arsitek mendesain kontrak bisnis terisolasi, atau saat modul tersebut merupakan domain inti (*core domain*) yang sering berubah aturan bisnisnya dan memerlukan *automated regression test* yang sangat ketat.

### 4. Bagian mana dari usulan AI yang Anda tolak atau sederhanakan, dan mengapa?
1. **Menolak Penggunaan Package Eksternal untuk Functional Error Handling**:
   AI mengusulkan library `fpdart` / `dartz` (`Either<Failure, T>`). Kami menolaknya dan memilih **Dart 3 Records** murni: `({T? data, Failure? failure})`. Alasan: Mengurangi bloat dependency pihak ketiga dan memanfaatkan fitur native Dart yang lebih mudah dipahami mahasiswa.
2. **Menyederhanakan Granularitas Use Case**:
   AI mengusulkan pembuatan `RefreshTokenUseCase` terpisah. Kami menolaknya dan menempatkan logika refresh token langsung pada HTTP interceptor di layer data, karena refresh token adalah concern infrastruktur jaringan, bukan operasi yang dipicu langsung oleh interaksi pengguna di UI.
3. **Menolak Service Locator Eksternal (`get_it`)**:
   AI mengusulkan kombinasi `get_it` + Riverpod. Kami menyederhanakannya murni menggunakan Riverpod providers untuk seluruh hierarki Dependency Injection, menjaga arsitektur tetap terpadu tanpa redundansi container DI.
