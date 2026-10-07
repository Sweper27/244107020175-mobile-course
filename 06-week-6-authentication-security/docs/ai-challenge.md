# AI Challenge — Jobsheet 6

## 1. Prompt yang Digunakan

Prompt lengkap diberikan kepada AI assistant untuk mengimplementasikan seluruh bagian Jobsheet Week 6: Authentication, Security & FCM. Prompt mencakup 26 bagian detail meliputi:

- Mock Authentication dengan credential `mahasiswa@kampus.ac.id` / `123456`
- Secure Storage menggunakan `flutter_secure_storage`
- Dio API Client dengan interceptor untuk auto token dan 401 refresh
- Riverpod Auth State dengan `AsyncNotifier`
- GoRouter route guard
- Login Page, Home Page, Announcement Page
- Firebase Cloud Messaging (FCM) setup
- Foreground, Background, dan Terminated notification handling
- Notification click navigation ke `/pengumuman/:id`
- Unit testing
- Dokumentasi

## 2. Fitur yang Diminta

| No | Fitur |
|----|-------|
| 1  | Mock Authentication (login/logout) |
| 2  | Secure Storage (access token & refresh token) |
| 3  | Dio Interceptor (auto token attach, 401 refresh) |
| 4  | Riverpod state management (auth state) |
| 5  | GoRouter route guard (redirect auth) |
| 6  | Login Page dengan loading & error handling |
| 7  | Home Page dengan logout |
| 8  | Announcement Page (dari notification) |
| 9  | Firebase Cloud Messaging setup |
| 10 | Foreground notification (local notification) |
| 11 | Background notification handler |
| 12 | Terminated state notification |
| 13 | Notification click → navigation |
| 14 | Unit test minimal |
| 15 | README dokumentasi |

## 3. Hasil Implementasi

Semua 15 fitur berhasil diimplementasikan oleh AI:

- **Data layer**: `token_store.dart`, `auth_repository.dart`, `api_client.dart`
- **State management**: `auth_provider.dart` menggunakan Riverpod `AsyncNotifier`
- **Routing**: `app_router.dart` dengan GoRouter + route guard
- **Pages**: `login_page.dart`, `home_page.dart`, `announcement_page.dart`
- **Services**: `notification_service.dart` menangani FCM + local notification
- **Android config**: build.gradle.kts, AndroidManifest.xml, settings.gradle.kts
- **Firebase**: Dikonfigurasi menggunakan FlutterFire CLI
- **Tests**: Unit test untuk token store, auth repository, notification payload, routes

## 4. Perubahan yang Dilakukan AI

| File | Aksi |
|------|------|
| `pubspec.yaml` | Ditambahkan semua dependency |
| `lib/main.dart` | Entry point dengan Firebase init & notification setup |
| `lib/data/token_store.dart` | Baru — secure token storage |
| `lib/data/auth_repository.dart` | Baru — mock auth |
| `lib/data/api_client.dart` | Baru — Dio + interceptor |
| `lib/providers/auth_provider.dart` | Baru — Riverpod auth state |
| `lib/router/app_router.dart` | Baru — GoRouter + guard |
| `lib/pages/login_page.dart` | Baru — login UI |
| `lib/pages/home_page.dart` | Baru — home UI |
| `lib/pages/announcement_page.dart` | Baru — pengumuman detail |
| `lib/services/notification_service.dart` | Baru — FCM & local notification |
| `android/app/build.gradle.kts` | Updated — desugaring, Google Services |
| `android/settings.gradle.kts` | Updated — Google Services plugin |
| `android/app/src/main/AndroidManifest.xml` | Updated — permission, FCM channel |
| `test/auth_test.dart` | Baru — unit tests |
| `README.md` | Baru — dokumentasi |
| `docs/ai-challenge.md` | Baru — dokumen ini |

## 5. Perbaikan Manual

Hal-hal yang mungkin perlu disesuaikan secara manual:

1. **Firebase Configuration** — Jika `flutterfire configure` belum dijalankan, perlu dijalankan manual.
2. **google-services.json** — Harus ada di `android/app/`.
3. **firebase_options.dart** — Harus di-generate oleh FlutterFire CLI.
4. **Testing FCM** — Membutuhkan Firebase Console untuk mengirim test notification.
5. **Identitas di README** — Nama, NIM, dan Kelas perlu diisi manual.

## 6. Testing

### Unit Test
```bash
flutter test
```

### Manual Test Checklist
- [ ] Login dengan credential benar → masuk Home
- [ ] Login dengan credential salah → error message
- [ ] Logout → kembali ke Login
- [ ] Route guard: akses `/` tanpa login → redirect `/login`
- [ ] Route guard: akses `/login` saat sudah login → redirect `/`
- [ ] FCM Token diperoleh (cek log)
- [ ] Foreground notification → tampil di tray
- [ ] Background notification → tampil di tray, klik → `/pengumuman/3`
- [ ] Terminated notification → klik → buka app → `/pengumuman/3`

## 7. Hasil Akhir

Project berhasil diimplementasikan dengan seluruh fitur Jobsheet 6. Kode bersih, terstruktur sesuai konsep codelab, dan siap untuk pengujian di perangkat Android fisik.

