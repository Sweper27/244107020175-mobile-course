# Dokumentasi Arsitektur — Clean Architecture (Feature-First)

Dokumen ini menjelaskan rancangan arsitektur, diagram layer, aturan dependensi (*dependency rules*), dan pemetaan file lama (Minggu 6) ke file baru (Minggu 7).

---

## 1. Diagram Tiga Layer dan Arah Dependensi

Arsitektur aplikasi menerapkan Clean Architecture dengan pendekatan **Feature-First**.

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

### Dependency Rules:
1. **Arah Panah Hanya Mengarah ke Dalam (ke arah Domain)**:
   - `Presentation` -> `Domain`
   - `Data` -> `Domain`
   - `Domain` **TIDAK PERNAH** mengimpor `Presentation` maupun `Data`.
2. **Domain Steril Framework**:
   - `Domain` tidak memiliki dependensi pada `flutter`, `dio`, `sqflite`, `firebase`, atau `flutter_riverpod`.
   - Hal ini memastikan logika bisnis murni (*pure Dart*) dapat diuji secara terisolasi tanpa mock framework berat.
3. **Pemisahan Entity vs Model**:
   - `Entity` berada di Domain: murni objek data bisnis tanpa method serialisasi (`toMap`, `fromJson`).
   - `Model` berada di Data: bertanggung jawab atas konversi serialisasi (`fromMap`, `toMap`, `toEntity()`).
4. **Kontrak Repository di Domain, Implementasi di Data**:
   - `AuthRepository` & `AnnouncementRepository` (abstract class/interface) berada di Domain.
   - `AuthRepositoryImpl` & `AnnouncementRepositoryImpl` berada di Data.
5. **Dependency Injection**:
   - Dikelola terpusat menggunakan Riverpod providers pada subfolder `presentation/providers/`.
   - Widget dilarang keras menginstansiasi repository secara langsung (`new Repository()`).

---

## 2. Struktur Folder Feature-First

```text
lib/
├── core/
│   ├── failures.dart                                # Definisi Failure sealed class
│   └── format.dart                                  # Pure utility functions (formatting & route parsing)
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart                   # Pure Dart entity
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart             # Abstract interface
│   │   │   └── usecases/
│   │   │       ├── check_auth_status_usecase.dart   # Verifikasi status aktif
│   │   │       ├── login_usecase.dart               # Validasi & proses login
│   │   │       └── logout_usecase.dart              # Pembersihan sesi
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── api_client.dart                  # Dio + interceptor token refresh
│   │   │   │   └── token_store.dart                 # FlutterSecureStorage wrapper
│   │   │   ├── models/
│   │   │   │   └── auth_user_model.dart             # Model + serialisasi & toEntity()
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart        # Implementasi AuthRepository
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── home_page.dart                   # Halaman beranda sesudah login
│   │       │   └── login_page.dart                  # Halaman login formulir
│   │       └── providers/
│   │           └── auth_providers.dart              # Riverpod DI & AuthNotifier
│   └── announcements/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── announcement.dart                # Pure Dart entity
│       │   ├── repositories/
│       │   │   └── announcement_repository.dart     # Abstract interface
│       │   └── usecases/
│       │       ├── get_announcement_by_id.dart      # Ambil detail pengumuman
│       │       └── get_announcements.dart           # Ambil daftar pengumuman
│       ├── data/
│       │   ├── models/
│       │   │   └── announcement_model.dart          # Model + mapping toEntity()
│       │   └── repositories/
│       │       └── announcement_repository_impl.dart# Implementasi repository data
│       └── presentation/
│           ├── pages/
│           │   └── announcement_page.dart           # UI detail pengumuman
│           └── providers/
│               └── announcement_providers.dart      # Riverpod DI & state providers
├── services/
│   └── notification_service.dart                    # Firebase FCM & Local Notifications
├── firebase_options.dart                            # Konfigurasi platform Firebase
├── routes.dart                                      # GoRouter configuration & guards
└── main.dart                                        # Entrypoint aplikasi
```

---

## 3. Pemetaan File Lama ke File Baru

| File Lama (Minggu 6) | Status | Lokasi Baru (Minggu 7 Clean Architecture) | Alasan & Transformasi |
| :--- | :--- | :--- | :--- |
| `lib/data/auth_repository.dart` | Dipecah | `lib/features/auth/domain/repositories/auth_repository.dart` (interface)<br>`lib/features/auth/data/repositories/auth_repository_impl.dart` (impl) | Memisahkan kontrak bisnis murni dari implementasi teknis. Mengubah return type menjadi Record `({T? data, Failure? failure})`. |
| `lib/data/token_store.dart` | Dipindah | `lib/features/auth/data/datasources/token_store.dart` | Menempatkan datasource secure storage di layer Data spesifik fitur auth. |
| `lib/data/api_client.dart` | Dipindah | `lib/features/auth/data/datasources/api_client.dart` | Menyimpan Dio client dan refresh interceptor di data layer auth. |
| `lib/providers/auth_provider.dart` | Dipindah & Direfactor | `lib/features/auth/presentation/providers/auth_providers.dart` | Notifier direfactor agar hanya memanggil UseCase, bukan langsung mengikat implementasi konkrit. |
| `lib/pages/login_page.dart` | Dipindah | `lib/features/auth/presentation/pages/login_page.dart` | UI dipindahkan ke Presentation layer auth. Menggunakan riverpod notifier. |
| `lib/pages/home_page.dart` | Dipindah | `lib/features/auth/presentation/pages/home_page.dart` | UI beranda dipindahkan ke Presentation layer auth. |
| `lib/pages/announcement_page.dart` | Dipecah & Direfactor | `lib/features/announcements/presentation/pages/announcement_page.dart`<br>`lib/features/announcements/data/repositories/announcement_repository_impl.dart` | Mengeluarkan hardcoded mock data dari widget ke repository data layer. UI menjadi consumer murni state provider. |
| `lib/router/app_router.dart` | Dipindah & Direfactor | `lib/routes.dart` | Konfigurasi rute disesuaikan dengan Clean Architecture routes. |
| `lib/services/notification_service.dart` | Dipertahankan | `lib/services/notification_service.dart` | Tetap mengelola FCM & Local Notifications tanpa mencemari Domain. |
| `lib/main.dart` | Diupdate | `lib/main.dart` | Memperbarui rute import ke `routes.dart` dan menyembunyikan debug log dengan `developer.log`. |
| *(Baru)* | Dibuat | `lib/core/failures.dart` | Hierarki failure domain (murni Dart). |
| *(Baru)* | Dibuat | `lib/core/format.dart` | Fungsi murni formatting tanggal, chip, dan route parsing. |
| *(Baru)* | Dibuat | `lib/features/auth/domain/entities/auth_user.dart` | Entity user murni Dart. |
| *(Baru)* | Dibuat | `lib/features/auth/data/models/auth_user_model.dart` | Model user dengan mapping. |
| *(Baru)* | Dibuat | `lib/features/auth/domain/usecases/*.dart` | Use cases untuk login, logout, dan status check. |
| *(Baru)* | Dibuat | `lib/features/announcements/domain/entities/announcement.dart` | Entity pengumuman murni Dart. |
| *(Baru)* | Dibuat | `lib/features/announcements/data/models/announcement_model.dart` | Model pengumuman dengan mapping. |
| *(Baru)* | Dibuat | `lib/features/announcements/domain/usecases/*.dart` | Use cases untuk pengambilan pengumuman. |
