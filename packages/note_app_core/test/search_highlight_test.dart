import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('cariPosisiHighlight', () {
    test('menemukan kemunculan tunggal', () {
      expect(
        cariPosisiHighlight('belajar flutter di rumah', 'flutter'),
        [8],
      );
    });

    test('pencocokan case-insensitive', () {
      expect(
        cariPosisiHighlight('Flutter flutter FLUTTER', 'flutter'),
        [0, 8, 16],
      );
    });

    test('menemukan semua kemunculan tanpa tumpang tindih', () {
      expect(
        cariPosisiHighlight('aaaa', 'aa'),
        [0, 2],
      );
    });

    test('keyword tidak ada -> daftar kosong', () {
      expect(cariPosisiHighlight('belajar dart', 'flutter'), isEmpty);
    });

    test('keyword kosong -> daftar kosong', () {
      expect(cariPosisiHighlight('belajar flutter', ''), isEmpty);
    });

    test('teks kosong -> daftar kosong', () {
      expect(cariPosisiHighlight('', 'flutter'), isEmpty);
    });

    test('keyword lebih panjang dari teks -> daftar kosong', () {
      expect(cariPosisiHighlight('ab', 'abc'), isEmpty);
    });

    test('posisi menunjuk tepat ke teks aslinya', () {
      const teks = 'Catatan RAFASYA tentang/flutter';
      final posisi = cariPosisiHighlight(teks, 'flutter');
      expect(posisi, [24]);
      expect(teks.substring(posisi.first, posisi.first + 'flutter'.length),
          'flutter');
    });

    test('offset tidak bergeser untuk karakter lowercase panjang berbeda', () {
      // 'İ' (U+0130) jadi 'i̇' (2 unit) kalau di-lowercase. Kalau pencocokan
      // memakai teks lowercase sebagai acuan, offset setelah karakter itu
      // bergeser satu karakter dan highlight menyasar teks yang salah.
      const teks = 'İstanbul flutter';
      final posisi = cariPosisiHighlight(teks, 'flutter');
      expect(posisi, [9]);
      expect(teks.substring(posisi.first, posisi.first + 7), 'flutter');
    });

    test('huruf besar khusus tidak dianggap sama dengan huruf kecil biasa', () {
      // 'ß' tidak sama dengan 'ss' (2 unit) - tidak boleh dicocokkan.
      expect(cariPosisiHighlight('straße', 'ss'), isEmpty);
    });

    test('semua posisi adalah kemunculan yang valid', () {
      const teks = 'satu dua tiga dua empat';
      final posisi = cariPosisiHighlight(teks, 'dua');
      expect(posisi, [5, 14]);
      for (final p in posisi) {
        expect(teks.substring(p, p + 3).toLowerCase(), 'dua');
      }
    });
  });
}
