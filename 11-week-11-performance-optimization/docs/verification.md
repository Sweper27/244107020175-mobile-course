# Dokumentasi Verifikasi dan Kualitas Kode — Jobsheet 7

Dokumen ini mencatat seluruh perintah verifikasi arsitektur, hasil eksekusi terminal, dan pembuktian kepatuhan terhadap *Dependency Rules*.

---

## 1. Perintah Verifikasi Dependensi (Sterility Checks)

### Uji 1: Presentation Steril dari Data Mentah & Datasource Langsung
Memastikan widget di presentation tidak memanggil `Dio`, `openDatabase`, `getDatabasesPath`, `FlutterSecureStorage`, `SharedPreferences`, atau `jsonDecode` secara langsung.

**Perintah PowerShell:**
```powershell
Get-ChildItem -Path "lib/features/*/presentation/pages" -Recurse -Include *.dart | Select-String -Pattern "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode|RepositoryImpl|Repository\("
```
**Hasil:**
```text
(0 hasil / Kosong)
```
**Kesimpulan:** Lolos. Halaman/Widget hanya mengonsumsi state dan memanggil Notifier melalui Riverpod.

---

### Uji 2: Domain Steril dari Framework Flutter & Package Eksternal
Memastikan folder `domain/` dan `core/` murni Dart tanpa mengimpor `flutter`, `dio`, `sqflite`, `firebase`, atau `flutter_riverpod`.

**Perintah PowerShell:**
```powershell
Get-ChildItem -Path "lib/features/*/domain", "lib/core" -Recurse -Include *.dart | Select-String -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase|import 'package:flutter_riverpod"
```
**Hasil:**
```text
(0 hasil / Kosong)
```
**Kesimpulan:** Lolos. Domain 100% murni Dart (*pure Dart*).

---

### Uji 3: Entity Steril dari Serialization / Mapping
Memastikan entity bisnis tidak memuat method `toMap`, `fromMap`, `toJson`, atau `fromJson`.

**Perintah PowerShell:**
```powershell
Get-ChildItem -Path "lib/features/*/domain/entities" -Recurse -Include *.dart | Select-String -Pattern "toMap|fromMap|toJson|fromJson"
```
**Hasil:**
```text
(0 hasil / Kosong)
```
**Kesimpulan:** Lolos. Seluruh proses serialisasi diisolasi pada Model di Data layer (`features/*/data/models/`).

---

### Uji 4: Widget Bebas dari Instansiasi Manual (Dependency Injection Terpusat)
Memastikan tidak ada pembuatan objek repository manual (`new Repository()` atau `Repository(...)`) di dalam file widget/page.

**Perintah PowerShell:**
```powershell
Get-ChildItem -Path "lib/features/*/presentation/pages" -Recurse -Include *.dart | Select-String -Pattern "AuthRepositoryImpl\(|AnnouncementRepositoryImpl\("
```
**Hasil:**
```text
(0 hasil / Kosong)
```
**Kesimpulan:** Lolos. Seluruh dependensi disuntikkan melalui Riverpod providers (`ref.watch` / `ref.read`).

---

## 2. Hasil Eksekusi Static Analysis (`flutter analyze`)

**Perintah:**
```bash
flutter analyze
```

**Output Terminal Nyata:**
```text
Analyzing 07-week-7-clean-architecture...                       
No issues found! (ran in 2.7s)
```
Status: **BERSIH (0 Issues / 0 Errors / 0 Warnings / 0 Info)**.

---

## 3. Hasil Eksekusi Unit Test (`flutter test`)

**Perintah:**
```bash
flutter test
```

**Output Terminal Nyata:**
```text
00:00 +0: loading test/announcement_usecase_test.dart
00:00 +0: test/announcement_usecase_test.dart: GetAnnouncementById UseCase Tests 1. Skenario Sukses: Mengembalikan announcement yang sesuai dari fake repository
00:00 +1: test/announcement_usecase_test.dart: GetAnnouncementById UseCase Tests 2. Skenario Gagal: Mengembalikan Failure yang benar tanpa membocorkan exception ke presentation
00:00 +2: test/announcement_usecase_test.dart: GetAnnouncementById UseCase Tests 3. Skenario Gagal: Validasi input kosong mengembalikan NotFoundFailure
00:00 +3: test/announcement_usecase_test.dart: GetAnnouncements UseCase Tests 4. Skenario Sukses: Mengembalikan seluruh daftar announcement dari fake repository
00:00 +4: test/auth_test.dart: TokenStore 1. save stores tokens correctly
00:00 +5: test/auth_test.dart: TokenStore 2. readAccess returns null when empty
00:00 +6: test/auth_test.dart: TokenStore 3. readRefresh returns null when empty
00:00 +7: test/auth_test.dart: TokenStore 4. clear removes all tokens
00:00 +8: test/auth_test.dart: AuthRepository 5. login succeeds with correct credentials
00:01 +18: test/auth_test.dart: AuthRepository 6. login fails with wrong email
00:01 +19: test/auth_test.dart: AuthRepository 7. login fails with wrong password
00:02 +20: test/auth_test.dart: AuthRepository 8. logout clears all tokens
00:02 +21: test/auth_test.dart: AuthRepository 9. isLoggedIn returns true after login
00:03 +22: test/auth_test.dart: AuthRepository 10. isLoggedIn returns false when not logged in
00:03 +23: test/auth_test.dart: AuthRepository 11. isLoggedIn returns false after logout
00:03 +24: test/auth_test.dart: AuthRepository 12. refresh succeeds when refresh token exists
00:04 +25: test/auth_test.dart: AuthRepository 13. refresh fails when no refresh token (empty store)
00:04 +26: test/auth_test.dart: Notification Payload 14. announcementId extracted from data
00:04 +27: test/auth_test.dart: Notification Payload 15. missing announcementId returns null
00:04 +28: test/auth_test.dart: Routes 16. announcement route is correct
00:04 +29: test/auth_test.dart: Routes 17. login route is /login
00:04 +30: test/auth_test.dart: Routes 18. home route is /
00:04 +31: All tests passed!
```
Status: **SEMUA 31 TESTS LULUS (100% Pass Rate)**.

---

## 4. Hasil Pemformatan Kode (`dart format`)

**Perintah:**
```bash
dart format lib test
```

**Output Terminal Nyata:**
```text
Formatted 31 files (21 changed) in 0.20 seconds.
```
Status: **FORMATTED SECARA STANDAR DART STYLE GUIDE**.
