# AI Review vs Keputusan

## 1. Konteks

-   **PR:** `fix: improve email validation`
-   **Branch:** `feat/input-validation` → `develop`
-   **File yang direview:** `lib/core/format.dart` dan
    `test/format_test.dart`
-   **Jenis review:** Review AI berbasis diff PR yang diberikan dalam
    screenshot.
-   **Catatan:** Review ini bukan hasil otomatis GitHub Copilot. Temuan
    di bawah diperiksa berdasarkan regex dan test yang terlihat.

## 2. Prompt AI

``` text
Review PR Flutter ini sebagai senior Flutter dev.

Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.

Fokus: kebenaran, arsitektur, dan test. Abaikan style.

Berikan 5 temuan teratas + level (blocker/saran) + alasan + usulan
potongan kode perbaikan.

PENTING:
- Review hanya berdasarkan kode yang saya berikan.
- Jangan mengarang bug atau menganggap fitur yang tidak ada sebagai masalah.
- Jika konteks arsitektur tidak relevan dengan perubahan, jelaskan.
- Sertakan bukti kode untuk setiap temuan.
- Jika tidak ada 5 temuan nyata, berikan temuan yang benar-benar dapat dibuktikan saja.
```

## 3. Ringkasan hasil review awal

### Temuan A --- Regex masih menerima titik berulang pada bagian lokal

-   **Level:** Saran
-   **Bukti:** Bagian lokal regex mengizinkan titik (`.`) sebagai
    karakter berulang di dalam kelas karakter.
-   **Contoh yang perlu diuji:** `a..b@example.com`
-   **Analisis:** Pola saat ini berpotensi menerima alamat dengan dua
    titik berurutan sebelum `@`. Ini merupakan keterbatasan validasi
    regex saat ini.
-   **Keputusan:** Diterima sebagai temuan nyata untuk perbaikan
    lanjutan. Bukan blocker untuk tujuan PR ini, yaitu memperbaiki
    dukungan domain dengan akhiran lebih panjang.

### Temuan B --- Label domain dapat diawali tanda hubung

-   **Level:** Saran
-   **Bukti:** Pola label domain `[a-zA-Z0-9-]+` mengizinkan tanda
    hubung di posisi pertama atau terakhir.
-   **Contoh yang perlu diuji:** `user@-example.com`
-   **Analisis:** Berdasarkan pola regex yang terlihat, contoh ini dapat
    cocok meskipun label domain tidak semestinya diawali tanda hubung.
-   **Keputusan:** Diterima sebagai temuan nyata untuk perbaikan
    lanjutan. Perlu test regresi khusus sebelum regex diubah.

### Temuan C --- Test untuk domain panjang relevan

-   **Level:** Validasi positif
-   **Bukti:** Test menambahkan `admin@example.museum` sebagai email
    valid dan `admin@museum` sebagai email tidak valid.
-   **Keputusan:** Diterima. Kedua test sesuai dengan tujuan perubahan
    regex.

### Temuan D --- Test input tidak lengkap relevan

-   **Level:** Validasi positif
-   **Bukti:** Test menambahkan `admin@` dan mengharapkan hasil `false`.
-   **Keputusan:** Diterima. Test memeriksa input email yang tidak
    memiliki domain.

### Temuan E --- Mengubah arsitektur aplikasi tidak diperlukan berdasarkan diff

-   **Level:** Tidak relevan / ditolak jika disarankan tanpa bukti
-   **Bukti:** Diff yang diperiksa hanya mengubah helper validasi email
    dan unit test-nya.
-   **Keputusan:** Tolak rekomendasi untuk mengubah Riverpod, GoRouter,
    SQLite, Dio, atau lapisan Clean Architecture jika tidak ada bukti
    pelanggaran dependency rule dalam perubahan ini. Rekomendasi
    tersebut tidak didukung oleh diff.

## 4. Tabel saran dan keputusan

  -----------------------------------------------------------------------
  Temuan/saran            Keputusan               Alasan
  ----------------------- ----------------------- -----------------------
  Periksa titik berurutan Diterima untuk tindak   Regex berpotensi
  pada bagian lokal email lanjut                  menerima
                                                  `a..b@example.com`

  Periksa tanda hubung di Diterima untuk tindak   Regex berpotensi
  awal label domain       lanjut                  menerima
                                                  `user@-example.com`

  Tambahkan test domain   Diterima                Menguji dukungan
  `.museum`                                       akhiran domain lebih
                                                  panjang

  Tambahkan test untuk    Diterima                Menguji input yang
  `admin@`                                        tidak lengkap

  Ubah arsitektur         Ditolak                 Tidak relevan dengan
  aplikasi tanpa bukti                            perubahan helper dan
  dari diff                                       unit test
  -----------------------------------------------------------------------

## 5. Bukti pengujian

Berdasarkan hasil yang dicatat selama pengerjaan:

-   `flutter test`: **31 test berhasil**.
-   `flutter analyze`: **No issues found**.
-   `dart format lib/core/format.dart test/format_test.dart`:
    dijalankan.

Hasil tersebut adalah bukti untuk kondisi kode saat pengujian dilakukan.
Jika kode diubah lagi setelah pengujian, jalankan ulang test dan
analyzer sebelum mengklaim hasil terbaru.

## 6. Kesimpulan

Perubahan PR memperbaiki validasi untuk domain dengan akhiran lebih dari
empat karakter dan menambah test untuk domain panjang serta input tidak
lengkap. Review juga menemukan dua batasan regex yang layak
ditindaklanjuti: titik berurutan di bagian lokal dan tanda hubung pada
awal label domain. Perubahan arsitektur yang tidak didukung bukti dari
diff ditolak. PR sudah digabungkan ke branch `develop`; temuan lanjutan
tidak berarti PR tersebut perlu digabungkan ulang.
