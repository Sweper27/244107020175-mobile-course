# Checklist & Petunjuk Pengambilan Screenshot — Jobsheet 7

Folder ini berisi dokumentasi visual aplikasi sebelum (*before*) dan sesudah (*after*) penerapan Clean Architecture.

---

## 1. Daftar Screenshot yang Tersedia & Diperlukan

| Nama File | Deskripsi | Status |
| :--- | :--- | :--- |
| `Login.jpeg` | Tampilan Halaman Login sebelum refactor | Tersedia (dari Minggu 6) |
| `home.jpeg` | Tampilan Halaman Beranda (Home) sesudah login sebelum refactor | Tersedia (dari Minggu 6) |
| `notifikasi.jpeg` | Notifikasi FCM / Local Notification muncul di system tray | Tersedia (dari Minggu 6) |
| `pengumuman.jpeg` | Tampilan Halaman Detail Pengumuman sebelum refactor | Tersedia (dari Minggu 6) |
| `after-login.png` | Tampilan Halaman Login setelah Clean Architecture (UI identik, dipicu usecase) | Panduan di bawah |
| `after-home.png` | Tampilan Halaman Beranda setelah Clean Architecture | Panduan di bawah |
| `after-announcement.png`| Tampilan Halaman Detail Pengumuman setelah Clean Architecture | Panduan di bawah |
| `architecture-folders.png` | Screenshot susunan folder `lib/core` & `lib/features` pada project explorer VS Code | Panduan di bawah |
| `analyze-results.png` | Screenshot terminal menjalankan `flutter analyze` dengan hasil *No issues found!* | Panduan di bawah |
| `test-results.png` | Screenshot terminal menjalankan `flutter test` dengan hasil *All 31 tests passed!* | Panduan di bawah |

---

## 2. Cara Mengambil Screenshot Tambahan

1. **Screenshot Terminal (`test-results.png` & `analyze-results.png`)**:
   - Buka terminal VS Code di folder `07-week-7-clean-architecture`.
   - Jalankan `flutter analyze` lalu screenshot terminal.
   - Jalankan `flutter test` lalu screenshot terminal yang menampilkan 31 tests passed.
2. **Screenshot Explorer (`architecture-folders.png`)**:
   - Rentangkan (*expand*) folder `lib/core`, `lib/features/auth`, dan `lib/features/announcements` di sidebar VS Code.
   - Ambil screenshot sidebar explorer.
3. **Screenshot Aplikasi (`after-login.png`, `after-home.png`, `after-announcement.png`)**:
   - Jalankan aplikasi di emulator atau browser web: `flutter run -d chrome` atau `flutter run -d emulator-5554`.
   - Lakukan login dengan kredensial:
     - Email: `mahasiswa@kampus.ac.id`
     - Password: `123456`
   - Buka rute `/pengumuman/1` atau klik notifikasi untuk melihat halaman detail pengumuman.
