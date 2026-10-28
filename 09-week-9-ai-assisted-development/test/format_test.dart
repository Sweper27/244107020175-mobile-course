import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/core/format.dart';

void main() {
  group('Core Format & Parsing Tests', () {
    test('1. formatAnnouncementChip memformat string dengan benar', () {
      expect(formatAnnouncementChip('1'), 'Pengumuman #1');
      expect(formatAnnouncementChip('99'), 'Pengumuman #99');
      expect(formatAnnouncementChip(''), 'Pengumuman #0');
      expect(formatAnnouncementChip('   '), 'Pengumuman #0');
    });

    test(
      '2. parseAnnouncementId mengembalikan default ID saat null atau kosong',
      () {
        expect(parseAnnouncementId('42'), '42');
        expect(parseAnnouncementId(null), '0');
        expect(parseAnnouncementId(''), '0');
        expect(parseAnnouncementId('   '), '0');
      },
    );

    test('3. isValidEmail memvalidasi format email', () {
      expect(isValidEmail('mahasiswa@kampus.ac.id'), isTrue);
      expect(isValidEmail('admin@test.com'), isTrue);

      // Menguji domain dengan akhiran lebih dari empat karakter.
      expect(isValidEmail('admin@museum'), isFalse);
      expect(isValidEmail('admin@example.museum'), isTrue);

      // Menguji input email yang tidak valid.
      expect(isValidEmail('bukan-email'), isFalse);
      expect(isValidEmail('admin@'), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('4. maskToken menyamarkan token secara aman', () {
      expect(maskToken('mock_access_token_v1'), 'mock...n_v1');
      expect(maskToken(null), '(empty)');
      expect(maskToken(''), '(empty)');
      expect(maskToken('short'), '***');
    });
  });
}
