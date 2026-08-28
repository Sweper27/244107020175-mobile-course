## Tujuan
    Memahami ekosistem pengembangan aplikasi mobile, dasar bahasa pemrograman Dart (termasuk *null safety*), serta inisialisasi proyek Flutter awal.

## Perbedaan Hot Reload dan Hot Restart
    * Hot Reload : memuat ulang ui secara instant tanpa mengulang semua status aplikasi
    * Hot refresh : memuat ulang semua aplikasi dari awal dan menjalankan kembali fungsi main 

## Fitur Utama
    * Pemrograman dasar Dart (fungsi, class, dan fitur *null safety*).
    * Aplikasi profil sederhana menggunakan Flutter.    
## Stack Teknologi


## Refleksi

### 1. Kapan native lebih tepat dipilih daripada cross-platform?
Native lebih tepat dipilih ketika aplikasi membutuhkan akses mendalam ke fitur hardware spesifik (seperti sensor khusus, Bluetooth Low Energy kompleks, AR/VR), membutuhkan performa grafis super tinggi, atau saat ukuran file aplikasi harus seefisien mungkin.

### 2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?
Dalam UI deklaratif, UI adalah cerminan dari state. Ketika terjadi perubahan data/state, Flutter akan merender ulang bagian dari *widget tree* yang terikat dengan state tersebut untuk memperbarui tampilan secara otomatis.

### 3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?
Commit yang kecil dan berkala memudahkan pelacakan riwayat perubahan (*history*), mempermudah proses *code review*, dan meminimalkan konflik saat penggabungan kode (*merge*). Bagi portofolio, pesan commit yang rapi menunjukkan alur kerja profesional dan terstruktur kepada perekrut atau dosen.