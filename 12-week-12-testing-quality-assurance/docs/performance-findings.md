# Performance Findings — Jobsheet 11: Performance Optimization

**Mata Kuliah:** Pemrograman Mobile  
**Jobsheet:** 11 – Performance Optimization  
**Aplikasi:** Campus Notification (`campus_notification`)  
**Platform Target:** Android / iOS / Web / Desktop  

---

## Ringkasan Eksekutif

Berdasarkan inspeksi arsitektur dan analisis kode statis serta perilaku rendering pada aplikasi *Campus Notification* sebelum optimasi (baseline Week 10), ditemukan minimal 4 masalah performa utama yang berdampak langsung pada kelancaran antarmuka (*UI Thread* & *Raster Thread*), efisiensi konsumsi memori (*Heap RAM*), dan waktu respons jaringan.

Berikut adalah daftar temuan masalah performa yang teridentifikasi secara nyata di dalam kode sumber:

---

## Temuan 1: Widget Rebuild Berlebih pada Seluruh Hirarki Halaman Utama (*Unnecessary Full Page Rebuild*)

- **Kategori:** CPU & UI Thread Optimization
- **Lokasi Kode:**
  - File: `lib/features/auth/presentation/pages/home_page.dart`
  - Blok Kode Bermasalah:
    ```dart
    @override
    Widget build(BuildContext context) {
      final filteredAsync = ref.watch(filteredAnnouncementsProvider);
      final searchQuery = ref.watch(announcementSearchQueryProvider);
      ...
    ```
- **Penyebab Masalah:**
  1. `HomePage.build()` mengamati langsung provider `announcementSearchQueryProvider` dan `filteredAnnouncementsProvider` di tingkat root widget (`ConsumerStatefulWidget`).
  2. Setiap kali pengguna mengetik satu karakter ke dalam kolom pencarian (`TextField`), `onChanged` memperbarui `announcementSearchQueryProvider`. Hal ini memicu `ref.watch` untuk merebuild **seluruh widget tree `HomePage` dari akar**, termasuk `Scaffold`, `AppBar`, `IconButton` AI & Logout, serta card informasi sambutan (`_WelcomeCard`).
  3. Banyak widget struktural tidak menggunakan konstruktor `const`, memaksa Flutter merealokasi instance widget baru setiap frame pengetikan.
- **Dampak terhadap Aplikasi:**
  - Pemborosan siklus CPU pada *UI Thread*.
  - Menimbulkan penundaan (*input latency*) saat pengguna mengetik dengan cepat.
  - Risiko terlampauinya frame budget (16.67 ms untuk 60 FPS) akibat kalkulasi layout dan build ulang elemen statis yang seharusnya tidak berubah.

---

## Temuan 2: Eager Rendering pada List Pengumuman (*Ketiadaan Lazy Loading & Viewport Virtualization*)

- **Kategori:** UI Thread Layout & Memory Pressure
- **Lokasi Kode:**
  - File: `lib/features/auth/presentation/pages/home_page.dart`
  - Blok Kode Bermasalah:
    ```dart
    SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...
          Column(
            children: announcements.map((item) {
              return Card(...);
            }).toList(),
          ),
        ],
      ),
    )
    ```
- **Penyebab Masalah:**
  1. Penggunaan kombinasi `SingleChildScrollView` dan `Column` dengan metode mapping `.toList()` menghasilkan *eager rendering*.
  2. Seluruh elemen pengumuman diinstansiasi, diukur (*layout*), dan dicat (*paint*) sekaligus ke dalam memori pohon elemen, terlepas dari apakah elemen tersebut terlihat di layar (*viewport*) pengguna atau berada jauh di bawah layar.
  3. Item widget pengumuman tidak diisolasi dalam compositing layer terpisah (`RepaintBoundary`), sehingga ketika satu elemen berubah atau saat scrolling, seluruh viewport di-repaint ulang.
- **Dampak terhadap Aplikasi:**
  - Konsumsi memori melonjak seiring bertambahnya jumlah pengumuman.
  - Saat daftar pengumuman bertambah panjang, proses layout awal (*initial frame layout*) menjadi sangat berat.
  - Terjadi *frame jank* (frame drop merah/kuning di Flame Chart) saat pengguna melakukan scrolling cepat.

---

## Temuan 3: Permintaan Jaringan Berulang Tanpa Mekanisme Caching (*Redundant Data Fetch & Blocking Latency*)

- **Kategori:** Network & Repository Optimization
- **Lokasi Kode:**
  - File: `lib/features/announcements/data/repositories/announcement_repository_impl.dart`
  - File: `lib/features/auth/data/datasources/api_client.dart`
  - Blok Kode Bermasalah:
    ```dart
    @override
    Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
      try {
        await Future.delayed(const Duration(milliseconds: 150));
        final list = _storage.entries.map(...).toList();
        return (announcements: list, failure: null);
      } ...
    }
    ```
- **Penyebab Masalah:**
  1. Setiap kali navigasi masuk ke halaman pengumuman atau detail, repository selalu mengeksekusi pengambilan data ulang dengan penundaan latensi jaringan penuh (150 ms atau network roundtrip).
  2. Tidak terdapat penyimpanan cache lokal (*in-memory* maupun *disk cache*) untuk menyimpan data yang baru saja diambil.
  3. Ketiadaan strategi *Stale-While-Revalidate* menyebabkan antarmuka selalu menampilkan `CircularProgressIndicator` dan pengguna dipaksa menunggu data dimuat ulang, meskipun data pengumuman sebelumnya tidak mengalami perubahan.
  4. Ketika jaringan terputus (offline), aplikasi langsung melempar kegagalan/error tanpa menyediakan fallback ke data lokal yang sudah pernah diambil.
- **Dampak terhadap Aplikasi:**
  - Pengalaman pengguna (*User Experience*) lambat dan patah-patah karena loading indicator selalu muncul.
  - Pemborosan kuota data dan konsumsi daya radio seluler / Wi-Fi akibat request berulang.
  - Aplikasi menjadi tidak toleran terhadap kondisi jaringan yang buruk (*poor network resilience*).

---

## Temuan 4: Potensi Bottleneck Raster Thread pada Pemuatan dan Decoding Gambar (*Unbounded Image Memory Decode*)

- **Kategori:** Raster Thread (GPU) & Heap Memory
- **Lokasi Kode:**
  - File: `lib/features/announcements/presentation/pages/announcement_page.dart`
  - File: `lib/features/auth/presentation/pages/home_page.dart`
- **Penyebab Masalah:**
  1. Belum tersedianya konfigurasi caching gambar terpusat (*disk & memory caching*).
  2. Gambar dari jaringan (`Image.network` standar) tidak membatasi ukuran decoding pada memori (*memCacheWidth* / *memCacheHeight*). Gambar beresolusi tinggi (misal 2000x1200 px) akan didekode secara penuh ke dalam format bitmap mentah di memori GPU/RAM, padahal hanya ditampilkan pada thumbnail berukuran 48x48 px atau 200 px.
  3. Setiap thumbnail 2000x1200 px 32-bit RGBA dapat mengonsumsi lebih dari 9 MB memori RAM per gambar, memicu lonjakan Garbage Collection (GC) dan tekanan memori (*Memory Pressure*).
- **Dampak terhadap Aplikasi:**
  - *Raster Thread* mengalami bottleneck selama proses image decoding, menyebabkan frame drop saat render gambar.
  - Risiko aplikasi ditutup paksa oleh sistem operasi (*Out Of Memory / OOM Crash*) pada perangkat berspesifikasi rendah (*low-end devices*).

---

## Matriks Rekapitulasi Temuan

| No | Temuan Masalah | Lokasi Kode | Kategori Thread / Resource | Rencana Solusi Optimasi |
|---|---|---|---|---|
| 1 | Widget Rebuild berlebih saat input pencarian | `home_page.dart` | UI Thread (Dart Build) | Ekstraksi Widget `const`, Riverpod `.select()`, Lokalisasi Consumer |
| 2 | Eager rendering list pengumuman | `home_page.dart` | UI Thread & Layout | Migrasi ke Lazy Loading (`CustomScrollView` + `SliverList.builder`) & `RepaintBoundary` |
| 3 | Fetch data berulang tanpa cache | `announcement_repository_impl.dart`, `api_client.dart` | Network & UI Latency | Caching Repository dengan strategi **Stale-While-Revalidate** & Interceptor Cache |
| 4 | Decoding gambar tanpa batas resolusi memori | `announcement_page.dart`, `home_page.dart` | Raster Thread (GPU) & RAM | Integrasi `CachedNetworkImage` dengan `memCacheWidth` & `memCacheHeight` |
