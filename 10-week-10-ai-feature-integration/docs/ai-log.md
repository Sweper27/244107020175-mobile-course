# Dokumentasi AI-Assisted Development (ai-log.md)

Laporan proses kolaborasi manusia dan Artificial Intelligence (AI) dalam penambahan fitur pencarian pengumuman kampus dan informative empty state pada aplikasi **Campus Notification** berbasis Clean Architecture.

---

## 1. Tujuan Fitur yang Dibuat

Pada halaman utama (`HomePage`), daftar pengumuman kampus (`Daftar Pengumuman Kampus`) sebelumnya hanya menampilkan seluruh data secara statis berurutan. Tujuan dari fitur yang ditambahkan adalah:
1. **Pencarian Real-Time**: Memungkinkan mahasiswa mencari pengumuman tertentu berdasarkan kata kunci judul maupun isi pengumuman secara cepat tanpa *lag*.
2. **Informative Empty State**: Menyediakan visual dan informasi yang ramah serta solutif saat kata kunci pencarian tidak cocok dengan pengumuman mana pun, lengkap dengan tombol untuk mereset kata kunci secara instan.
3. **Kepatuhan Clean Architecture**: Memastikan logika penyaringan data ditempatkan pada layer yang benar (*Domain Use Case* dan *Presentation Provider*), bukan ditumpuk di dalam widget UI (*Separation of Concerns*).

---

## 2. Konteks Project yang Diberikan kepada AI

Konteks arsitektur dan pustaka project yang digunakan sebagai dasar instruksi kepada AI:
- **Framework**: Flutter 3.47.1, Dart 3.13.1 (Sound Null Safety).
- **Arsitektur**: Clean Architecture (*Feature-First*: `core/`, `features/auth/`, `features/announcements/` dengan subfolder `data/`, `domain/`, `presentation/`).
- **State Management**: `flutter_riverpod: ^2.6.1` (menggunakan `Provider`, `FutureProvider`, `StateProvider`).
- **Navigasi**: `go_router: ^14.8.1`.
- **Fitur Terkait**: Entitas `Announcement` (`id`, `title`, `body`, `date`), use case `GetAnnouncements`, provider `announcementsListProvider`.

---

## 3. Prompt Utama yang Digunakan

### Prompt 1 (Eksplorasi dan Pembuatan Fitur Awal)
> *"Saya memiliki aplikasi Flutter Clean Architecture dengan Riverpod 2.6. Di HomePage terdapat daftar pengumuman kampus yang dimuat melalui announcementsListProvider (FutureProvider<List<Announcement>>). Buatkan fitur pencarian teks real-time di HomePage beserta empty state ketika hasil pencarian tidak ditemukan. Kode harus bersih dan sesuai arsitektur."*

### Prompt 2 (Klarifikasi dan Penyesuaian Clean Architecture)
> *"Pisahkan logika filtering pengumuman ke dalam Domain UseCase murni agar dapat diuji secara independen dengan unit test tanpa dependensi UI maupun Riverpod. Di presentation layer, buat provider yang menggabungkan state kata kunci pencarian dengan list pengumuman yang sudah ada."*

### Prompt 3 (Pengujian Widget dan Penanganan Siklus Hidup)
> *"Buatkan unit test lengkap untuk UseCase dan Provider, serta widget test untuk HomePage guna memverifikasi interaksi pengetikan kata kunci, tampilan hasil yang difilter, dan tombol reset pada empty state."*

---

## 4. Ringkasan Output Awal AI

Output awal yang dihasilkan oleh AI secara umum:
1. AI menyarankan untuk menambahkan method baru `Future<List<Announcement>> searchAnnouncements(String query)` ke dalam interface `AnnouncementRepository` dan `AnnouncementRepositoryImpl`.
2. AI menyarankan membuat `TextField` di dalam `ConsumerWidget` dan melakukan pemfilteran langsung menggunakan metode `.where()` di dalam method `build()`.
3. String perbandingan pencarian awal hanya membandingkan `item.title.contains(query)` tanpa normalisasi huruf kecil (`.toLowerCase()`) dan tanpa pembersihan spasi (`.trim()`).
4. Tampilan ketika hasil kosong hanya berupa widget sederhana `Center(child: Text('Tidak ada hasil'))`.
5. Kode widget test yang disarankan AI mengabaikan ukuran batas viewport default Flutter test (`800x600`), sehingga pemanggilan `tester.tap()` pada tombol reset gagal karena posisi widget berada di koordinat Y=651px (di luar layar).

---

## 5. Hasil Verifikasi terhadap Kode dan API yang Digunakan

1. **Pemeriksaan Layer Arsitektur**:
   - Memodifikasi `AnnouncementRepository` untuk pencarian lokal adalah *overengineering* yang tidak perlu karena seluruh data pengumuman sudah di-*cache* dalam memori oleh `announcementsListProvider`. Menambahkan panggilan asinkron ke repository untuk filter in-memory hanya menimbulkan *boilerplate* dan *flicker* UI.
   - Menaruh logika filtering langsung di method `build()` melanggar prinsip *Separation of Concerns* (SoC).
2. **Pemeriksaan State Management Riverpod**:
   - Riverpod 2.6.1 mendukung `StateProvider<String>` untuk kata kunci dan `Provider<AsyncValue<List<Announcement>>>` turunan yang reaktif menggunakan `announcementsAsync.whenData(...)`. Ini menghasilkan transisi state instan dan sinkron.
3. **Pemeriksaan Siklus Hidup Controller**:
   - `TextEditingController` harus di-*dispose* untuk mencegah *memory leak*. Oleh karena itu, `HomePage` lebih aman diimplementasikan sebagai `ConsumerStatefulWidget` dengan `dispose()`.
4. **Pemeriksaan Logika String**:
   - Pengguna sering kali mengetik huruf kecil ("registrasi") sementara judul pengumuman menggunakan huruf kapital ("Registrasi Semester Baru"), atau menambahkan spasi tak sengaja di akhir kata kunci. Normalisasi `.trim().toLowerCase()` pada judul dan isi wajib dilakukan.

---

## 6. Tabel Keputusan Menerima atau Menolak Saran AI

| No | Saran AI | Keputusan | Alasan Teknis | Bukti Verifikasi |
|---|---|---|---|---|
| 1 | Menambahkan method `search()` ke `AnnouncementRepository` dan `AnnouncementRepositoryImpl` | **Reject** | Data pengumuman lokal sudah dimuat oleh `announcementsListProvider`. Menambah query ke repo menambah latensi dan melanggar prinsip kesederhanaan *Data Layer*. | File `lib/features/announcements/data/repositories/announcement_repository_impl.dart` |
| 2 | Menuliskan logika filter `.where()` langsung di dalam widget `HomePage.build()` | **Reject** | Melanggar *Separation of Concerns* Clean Architecture. Logika bisnis penyaringan tidak dapat diuji secara independen dengan unit test tanpa merender widget. | Prinsip Clean Architecture; modul codelab Jobsheet 7 & 9 |
| 3 | Membuat Use Case murni `SearchAnnouncements` di Domain Layer | **Accept** | Logika filter murni terisolasi dari UI dan framework data, sangat cepat, dan dapat diuji 100% menggunakan Dart pure test. | File `lib/features/announcements/domain/usecases/search_announcements.dart` |
| 4 | Menggunakan `StateProvider<String>` dan `filteredAnnouncementsProvider` di Riverpod | **Accept** | Sesuai dengan konvensi Riverpod 2.6.1; `whenData` otomatis menangani status *loading* dan *error* turunan tanpa menulis ulang kode penanganan state. | File `lib/features/announcements/presentation/providers/announcement_providers.dart` |
| 5 | Menggunakan `ConsumerWidget` murni dengan `TextEditingController` tanpa lifecycle management | **Modified** | `TextEditingController` yang tidak dibersihkan (`dispose()`) menyebabkan kebocoran memori. Diubah menjadi `ConsumerStatefulWidget` dengan `dispose()` yang tepat. | Static analysis & pedoman resmi Flutter Widget Lifecycle |
| 6 | Filter hanya mencocokkan `item.title.contains(query)` | **Modified** | Gagal jika user mencari kata pada isi pengumuman atau menggunakan huruf kecil/spasi ekstra. Diperbaiki: memeriksa `title` dan `body`, dengan `.trim().toLowerCase()`. | Hasil pengujian `test/search_announcements_test.dart` (test case 3, 4, 5, 6) |
| 7 | Tampilan kosong hanya `Text('Tidak ada pengumuman')` | **Modified** | UX buruk bagi pengguna karena tidak informatif. Diubah menjadi *Informative Empty State* dengan icon pencarian, teks penjelasan kata kunci, dan tombol "Reset Pencarian". | File `lib/features/auth/presentation/pages/home_page.dart` |
| 8 | Widget test memanggil `tester.tap()` langsung pada tombol reset | **Modified** | Gagal dengan peringatan bahwa tombol berada di Y=651px (di luar viewport 800x600). Diperbaiki dengan mengatur `tester.view.physicalSize` dan memanggil `tester.ensureVisible()`. | Log eksekusi `task-176.log` vs `test/search_widget_test.dart` |

---

## 7. Bukti Teknis untuk Setiap Keputusan

1. **Bukti Keputusan 1 & 2 (Pemisahan Layer)**:
   - Terbukti dari file `lib/features/announcements/domain/usecases/search_announcements.dart`:
     ```dart
     class SearchAnnouncements {
       const SearchAnnouncements();
       List<Announcement> call({
         required List<Announcement> announcements,
         required String query,
       }) { ... }
     }
     ```
   - Berkas ini tidak memiliki dependensi terhadap Flutter framework (`package:flutter`) maupun Riverpod, sehingga merupakan *Pure Business Logic*.

2. **Bukti Keputusan 3 & 4 (Reaktivitas Provider)**:
   - Divalidasi melalui 3 pengujian provider di `test/search_announcements_test.dart`:
     - Test 1: Inisialisasi query kosong.
     - Test 2: Pembaruan state query via `.notifier`.
     - Test 3: Reaktivitas `filteredAnnouncementsProvider` mengembalikan 3 item -> 1 item -> 0 item secara sinkron sesuai perubahan query.

3. **Bukti Keputusan 6 (Normalisasi Case & Trim)**:
   - Divalidasi melalui pengujian unit test 3, 4, 5, dan 6 di `test/search_announcements_test.dart`:
     - Input `'registrasi'` cocok dengan judul `'Registrasi Semester Baru'` (case-insensitive).
     - Input `'SISTEM'` cocok dengan judul `'Pemeliharaan Sistem'` (uppercase query).
     - Input `'Mobile Programming'` cocok dengan isi pengumuman jadwal kuliah.
     - Input `'   Kuliah   '` berhasil di-*trim* dan cocok dengan jadwal kuliah.

4. **Bukti Keputusan 8 (Perbaikan Widget Test)**:
   - Sebelum perbaikan, `flutter test test/search_widget_test.dart` melempar kegagalan:
     `Warning: A call to tap() with finder ... derived an Offset (Offset(408.0, 651.0)) that would not hit test on the specified widget.`
   - Setelah menambahkan `tester.view.physicalSize = const Size(800, 1200);` dan `await tester.ensureVisible(resetButton);`, pengujian berhasil hijau sempurna (*All tests passed*).

---

## 8. Perbaikan atau Refactoring yang Dilakukan terhadap Kode AI

1. **Arsitektur**:
   - Memindahkan logika penyaringan dari dalam widget ke `SearchAnnouncements` use case di domain layer.
   - Menghubungkan use case ke presentation layer melalui `searchAnnouncementsProvider` dan `filteredAnnouncementsProvider`.
2. **Kualitas UI & UX**:
   - Menambahkan tombol clear (`X`) pada kolom pencarian saat query terisi.
   - Membuat kartu informasi pencarian kosong dengan ikon `Icons.search_off_rounded` dan tombol aksi cepat `Reset Pencarian`.
3. **Kerapian Format Kode**:
   - Menjalankan `dart format .` untuk mematuhi konvensi resmi gaya kode Dart.
4. **Stabilitas Pengujian**:
   - Menambahkan unit test komprehensif (8 skenario use case, 3 skenario provider) dan widget test (interaksi pengguna lengkap).

---

## 9. Hasil Pengujian Akhir

Perintah dijalankan dari direktori `09-week-9-ai-assisted-development`:

1. **Format Kode**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   *Hasil*: Seluruh 34 berkas terformat rapi sesuai standar Dart.

2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   *Hasil*:
   ```text
   Analyzing 09-week-9-ai-assisted-development...
   No issues found! (ran in 2.4s)
   ```

3. **Unit & Widget Tests**:
   ```bash
   flutter test
   ```
   *Hasil*:
   ```text
   00:04 +43: All tests passed!
   ```
   - Total test lulus: **43 test** (31 test baseline Clean Architecture + 11 unit test fitur pencarian + 1 widget test).
   - Gagal: **0**.

---

## 10. Pelajaran yang Diperoleh dari AI-Assisted Development

1. **AI adalah Akselerator, Bukan Pengambil Keputusan**: AI sangat cepat dalam membuat kode dasar (*scaffolding*), namun rentan melanggar arsitektur seperti mencampuradukkan business logic ke dalam widget atau merekomendasikan modifikasi repository yang berlebihan.
2. **Pentingnya Verifikasi Mandiri**: Pengetahuan mengenai siklus hidup widget Flutter (`dispose`), batasan ukuran viewport saat widget testing, serta normalisasi string mutlak diperlukan oleh developer untuk menyaring keluaran AI.
3. **Konsep Vibe Coding yang Bertanggung Jawab**: Vibe coding yang efektif bukan sekadar "terima jadi", melainkan dialog iteratif: **Prompt $\to$ Generate $\to$ Verify $\to$ Test $\to$ Refactor $\to$ Explain**.
