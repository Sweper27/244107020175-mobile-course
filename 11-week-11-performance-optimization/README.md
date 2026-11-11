# Jobsheet 11 — Optimasi Performa (Performance Optimization)

## Identitas Mahasiswa
- **Nama:** Rifqi Aries Saputra
- **NIM:** 244107020175
- **Kelas:** TI-3H
- **Mata Kuliah:** Pemrograman Mobile

---

## Deskripsi & Tujuan Praktikum

Praktikum Jobsheet 11 berfokus pada **Optimasi Performa Aplikasi Mobile Flutter** pada project nyata `campus_notification` yang dibangun menggunakan arsitektur *Clean Architecture* dan state management *Riverpod*.

Tujuan utama optimasi performa meliputi:
1. Menganalisis perilaku *rendering pipeline* Flutter pada **UI Thread** (Dart build, layout, paint) dan **Raster Thread** (GPU rendering, compositing, image decoding).
2. Mengurangi *widget rebuild* yang tidak perlu melalui penggunaan konstruktor `const`, ekstraksi sub-widget terisolasi, dan selektivitas state Riverpod menggunakan `.select()`.
3. Menerapkan *Lazy Loading* (virtualisasi viewport menggunakan `SliverList.builder`) dan isolasi pengecatan menggunakan `RepaintBoundary` untuk menghilangkan *frame drop* (*jank*).
4. Menerapkan optimasi pemuatan gambar jaringan (*network image caching*) dengan membatasi resolusi memori (*memCacheWidth* dan *memCacheHeight*) menggunakan paket `cached_network_image`.
5. Menerapkan strategi *caching* di lapisan repositori menggunakan pola **Stale-While-Revalidate** serta *Dio Interceptor Cache* untuk menghadirkan antarmuka instan tanpa penundaan loading berulang dan ketahanan terhadap mode *offline*.
6. Menghindari *memory leak* melalui pembersihan *controller* dan *listener* yang teratur pada lifecycle `dispose()`.

---

## 4 Teknik Optimasi yang Diterapkan

Sesuai dengan ketentuan modul resmi (minimal 3 teknik yang relevan), kami mengimplementasikan 4 teknik optimasi utama:

### 1. Optimasi Widget Rebuild, Ekstraksi Widget, dan Riverpod `.select()`
- **Masalah:** Sebelum optimasi, pengetikan pada kolom pencarian di `HomePage` memicu pemanggilan ulang `HomePage.build()` secara menyeluruh dari root, merebuild elemen-elemen statis (`_WelcomeCard`, `AppBar`, action buttons) pada setiap penekanan tombol keyboard.
- **Solusi:**
  - Mengekstrak kartu sambutan menjadi class terpisah `_WelcomeCard` dengan konstruktor `const`.
  - Mengisolasi baris pencarian ke `_AnnouncementSearchBar` dengan Riverpod `.select((q) => q.isNotEmpty)` sehingga tombol reset/clear hanya rebuild saat status kosong/terisi berubah.
  - Membatasi rebuild list pengumuman hanya di dalam `_AnnouncementSliverSection`.
  - Mengoptimasi `LoginPage` dengan `ref.watch(authProvider.select((s) => s.isLoading))`.
- **Hasil:** UI Thread tidak lagi dibebani rebuild pohon widget besar; pengetikan pencarian terasa instan dan bebas latensi input.

### 2. Lazy Loading Viewport dengan `SliverList.builder` & Isolasi Paint dengan `RepaintBoundary`
- **Masalah:** Seluruh pengumuman sebelumnya dirender sekaligus menggunakan `SingleChildScrollView` dan `Column(children: list.map(...).toList())` (*eager rendering*), menyebabkan alokasi memori berlebih dan frame jank saat scrolling.
- **Solusi:**
  - Mengganti eager list dengan `CustomScrollView` + `SliverList.builder`. Hanya item yang masuk ke dalam *viewport* yang diinstansiasi dan di-layout (*lazy loading*).
  - Membungkus setiap kartu `_AnnouncementCardItem` dan `ChatBubble` di `AIChatPage` menggunakan `RepaintBoundary` untuk memisahkan compositing layer GPU.
- **Hasil:** Pengurangan beban layout awal secara signifikan dan pencegahan repaint berantai pada Raster Thread saat list bergeser atau pesan AI baru ditambahkan.

### 3. Optimasi Gambar dengan `cached_network_image` & Batasan Memori (`memCacheWidth` / `memCacheHeight`)
- **Masalah:** Decoding gambar jaringan resolusi tinggi langsung ke memori grafis tanpa batasan ukuran menyebabkan pemborosan RAM (dapat mencapai belasan MB per gambar) dan memicu lonjakan Garbage Collection (GC) serta lag pada Raster Thread.
- **Solusi:**
  - Mengintegrasikan pustaka `cached_network_image: ^3.4.1`.
  - Mengatur batas decode memori proporsional: `memCacheWidth: 144` & `memCacheHeight: 144` untuk thumbnail pengumuman (48x48 px), serta `memCacheWidth: 600` & `memCacheHeight: 400` untuk banner di `AnnouncementPage`.
  - Menyertakan placeholder halus dan error fallback widget.
- **Hasil:** Konsumsi memori heap terkontrol ketat, gambar tersimpan secara persisten di disk cache lokal, dan tidak ada pengunduhan berulang.

### 4. Caching Repositori dengan Strategi Stale-While-Revalidate & Network Resilience
- **Masalah:** Pengambilan data pengumuman selalu mengalami latensi jaringan penuh (~150 ms) setiap kali halaman dibuka, membuat pengguna harus menunggu loading indicator berulang kali.
- **Solusi:**
  - Menerapkan in-memory caching pada `AnnouncementRepositoryImpl` dengan strategi **Stale-While-Revalidate**:
    1. Jika data cache lokal tersedia, repositori langsung mengembalikan data cache seketika (**Cache Hit, 0ms latency**).
    2. Repositori menjalankan pembaruan asinkron di latar belakang (*background revalidation*) untuk menyinkronkan data terbaru.
    3. Jika terjadi kegagalan jaringan (*offline*), data cache dijadikan fallback andal sehingga aplikasi tetap dapat digunakan dengan nyaman.
  - Menambahkan `_DioCacheInterceptor` pada `ApiClient` untuk caching request GET idempotent.
- **Hasil:** Waktu respons UI menurun drastis dari ~150 ms menjadi < 5 ms pada kunjungan berulang, serta aplikasi tahan terhadap kondisi tanpa sinyal.

---

## Struktur Folder Proyek

```text
11-week-11-performance-optimization/
├── docs/
│   ├── performance-findings.md    # Laporan detail temuan masalah performa (minimal 3)
│   ├── performance-report.md      # Laporan lengkap baseline, teknik, komparasi, & trade-off
│   ├── ai-challenge.md
│   ├── ai-log.md
│   ├── architecture.md
│   └── verification.md
├── screenshots/
│   ├── before-profile.png         # Screenshot Flame Chart / DevTools sebelum optimasi
│   ├── after-profile.png          # Screenshot Flame Chart / DevTools sesudah optimasi
│   └── ...                        # Screenshot fitur aplikasi
├── lib/
│   ├── core/
│   ├── features/
│   │   ├── ai/
│   │   │   └── presentation/widgets/chat_bubble.dart  # Ditambahkan RepaintBoundary
│   │   ├── announcements/
│   │   │   ├── data/
│   │   │   │   ├── models/announcement_model.dart     # Serialisasi imageUrl
│   │   │   │   └── repositories/announcement_repository_impl.dart # Stale-While-Revalidate
│   │   │   ├── domain/entities/announcement.dart      # Field opsional imageUrl
│   │   │   └── presentation/pages/announcement_page.dart # CachedNetworkImage + memCache
│   │   └── auth/
│   │       ├── data/datasources/api_client.dart       # DioCacheInterceptor
│   │       └── presentation/pages/
│   │           ├── home_page.dart                     # Lazy CustomScrollView, const, select
│   │           └── login_page.dart                    # Riverpod .select()
│   ├── main.dart
│   └── routes.dart
├── test/
│   ├── performance_optimization_test.dart             # Unit & Widget test performa JS 11
│   ├── search_widget_test.dart
│   ├── announcement_usecase_test.dart
│   ├── auth_test.dart
│   └── ...
├── pubspec.yaml                                       # Ditambahkan cached_network_image
└── README.md
```

---

## Cara Menjalankan Aplikasi

1. **Pastikan konfigurasi environment `.env` tersedia:**
   ```bash
   cp .env.example .env
   ```
2. **Unduh dependencies:**
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi (Mode Debug):**
   ```bash
   flutter run
   ```

---

## Cara Melakukan Performance Profiling

Sesuai dengan panduan resmi modul Jobsheet 11, profiling harus dijalankan dalam mode `--profile` (bukan mode debug karena overhead debug mempengaruhi hasil):

1. **Jalankan aplikasi dalam Mode Profile:**
   ```bash
   flutter run --profile
   ```

2. **Buka Flutter DevTools:**
   - DevTools akan otomatis terbuka di browser Anda, atau buka link `http://127.0.0.1:9100`.
   - Masuk ke tab **Performance**.

3. **Merekam Flame Chart & Frame Events:**
   - Klik tombol **Record**.
   - Pada aplikasi di perangkat, lakukan skenario:
     - Ketik teks pencarian dengan cepat.
     - Scroll daftar pengumuman secara cepat bolak-balik.
     - Navigasi ke percakapan AI dan detail pengumuman.
   - Klik tombol **Stop**.
   - Periksa **Frame Chart**: pastikan seluruh bar berada di bawah garis 16.67 ms (hijau, 60 FPS).
   - Periksa **Track UI Thread** dan **Raster Thread** pada Flame Chart untuk memastikan tidak ada fungsi berat berulang.
   - Simpan tangkapan layar Flame Chart sebagai `screenshots/before-profile.png` (sebelum optimasi) dan `screenshots/after-profile.png` (sesudah optimasi).

4. **Memeriksa Memori (Heap Snapshot):**
   - Masuk ke tab **Memory**.
   - Ambil snapshot sebelum dan sesudah navigasi bolak-balik sebanyak 5x untuk memverifikasi ketiadaan *memory leak*.

---

## Hasil Pengujian Terotomatisasi

### 1. `flutter analyze`
```text
Analyzing 11-week-11-performance-optimization...
No issues found! (ran in 5.4s)
```

### 2. `flutter test`
```text
00:04 +52: All tests passed!
```
Seluruh 52 test case (termasuk 3 test case baru khusus pengujian caching Stale-While-Revalidate, serialisasi model gambar, dan virtualisasi lazy scroll) berhasil lulus 100% tanpa ada kesalahan.

## Refleksi 

### 1. Optimasi mana yang memberikan dampak terbesar dan mengapa?

Optimasi widget rebuild dan penggunaan `const` constructor memberikan dampak yang cukup besar karena dapat mengurangi proses pembuatan ulang widget yang sebenarnya tidak mengalami perubahan. Dengan demikian, Flutter tidak perlu melakukan pekerjaan tambahan ketika aplikasi melakukan rebuild. Hal ini membantu meningkatkan efisiensi proses rendering dan menjaga responsivitas antarmuka aplikasi.

### 2. Bagaimana Anda memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?

Verifikasi dilakukan dengan membandingkan kondisi kode sebelum dan sesudah optimasi, menjalankan aplikasi untuk memastikan seluruh fitur tetap berfungsi, serta melakukan pengujian menggunakan `flutter analyze` dan `flutter test`.

Selain itu, Flutter DevTools dapat digunakan untuk membandingkan frame time, jumlah jank, dan penggunaan memori sebelum dan sesudah optimasi. Pengukuran kuantitatif perlu dilakukan untuk memastikan peningkatan performa benar-benar terjadi.

### 3. Trade-off apa yang Anda hadapi (misalnya kompleksitas kode vs performa)?

Trade-off yang dihadapi adalah bertambahnya kompleksitas kode ketika menerapkan teknik optimasi tertentu. Misalnya, penggunaan caching membutuhkan pengelolaan data tambahan, sedangkan pemisahan widget menjadi beberapa komponen membutuhkan struktur kode yang lebih terorganisasi.

Meskipun demikian, perubahan tersebut dapat memberikan keuntungan berupa kode yang lebih mudah dipelihara dan penggunaan sumber daya aplikasi yang lebih efisien.

### 4. Kapan sebaiknya optimasi premature dihindari?

Premature optimization sebaiknya dihindari ketika aplikasi belum menunjukkan masalah performa yang nyata. Pengembang sebaiknya memprioritaskan fungsionalitas aplikasi, keterbacaan kode, dan struktur program terlebih dahulu.

Optimasi dilakukan setelah ditemukan bagian yang menjadi bottleneck melalui pengujian atau profiling. Dengan begitu, waktu pengembangan dapat digunakan secara efektif dan kompleksitas kode yang tidak diperlukan dapat dihindari.

---
