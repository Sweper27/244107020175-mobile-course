# Jobsheet 7 — Clean Architecture

Laporan Praktikum Pemrograman Mobile: Implementasi Arsitektur Bersih (*Clean Architecture*) dengan Pendekatan *Feature-First* pada Flutter.

---

## 1. Identitas Mahasiswa

| Informasi | Keterangan |
| :--- | :--- |
| **Nama** | Rifqi Aries Saputra |
| **NIM** | 244107020175 |
| **Kelas** | TI-3H |

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

## 3. Fitur yang Berhasil Direfactor

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


## 4. Menjalankan Static Analysis
```bash
flutter analyze
```
*Hasil: <img src="screenshots/analyze.png" width= "300">

### 3. Menjalankan Unit Tests
```bash
flutter test
```
*Hasil: <img src="screenshots/test.png" width= "300">

---


## 5. Daftar Screenshot yang Perlu Diambil

<img src="screenshots/home.jpeg" width= "300">

<img src="screenshots/Login.jpeg" width= "300">

<img src="screenshots/notifikasi.jpeg" width= "300">

<img src="screenshots/pengumuman.jpeg" width= "300">

---

## 6. Kesimpulan dan Refleksi

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
