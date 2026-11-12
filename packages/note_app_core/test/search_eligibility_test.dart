import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('catatanLayakTampil', () {
    test('catatan biasa (isi plaintext) selalu layak', () {
      expect(
        catatanLayakTampil(
          judul: 'Catatan Biasa',
          plainTersimpan: 'isi biasa',
          plainDidekripsi: 'isi biasa',
          query: 'biasa',
        ),
        isTrue,
      );
    });

    test('catatan terkunci yang cocok lewat judul tetap layak', () {
      // Judul disimpan plaintext, jadi LIKE pada kolom title tetap valid
      // walau isi catatan terenkripsi.
      expect(
        catatanLayakTampil(
          judul: 'Rahasia Kantor',
          plainTersimpan: 'NBNOTE1.abc.def.ghi',
          plainDidekripsi: 'isi terenkripsi',
          query: 'Rahasia',
        ),
        isTrue,
      );
    });

    test('catatan terkunci yang isi dekripsinya mengandung kata kunci layak', () {
      expect(
        catatanLayakTampil(
          judul: 'Tanpa Judul',
          plainTersimpan: 'NBNOTE1.abc.def.ghi',
          plainDidekripsi: 'rahasia di dalam isi',
          query: 'rahasia',
        ),
        isTrue,
      );
    });

    test('catatan terkunci yang isinya tidak mengandung kata kunci dibuang', () {
      // Ciphertext bisa saja mengandung potongan kata kunci - itu hanya
      // kebetulan, bukan hasil yang benar.
      expect(
        catatanLayakTampil(
          judul: 'Tanpa Judul',
          plainTersimpan: 'NBNOTE1.abc.def.ghi',
          plainDidekripsi: 'isi lain',
          query: 'rahasia',
        ),
        isFalse,
      );
    });

    test('catatan terkunci yang gagal didekripsi dibuang', () {
      expect(
        catatanLayakTampil(
          judul: 'Tanpa Judul',
          plainTersimpan: 'NBNOTE1.abc.def.ghi',
          plainDidekripsi: 'NBNOTE1.abc.def.ghi',
          query: 'rahasia',
        ),
        isFalse,
      );
    });

    test('pencocokan tidak membedakan huruf besar-kecil', () {
      expect(
        catatanLayakTampil(
          judul: 'Rahasia Kantor',
          plainTersimpan: 'NBNOTE1.abc.def.ghi',
          plainDidekripsi: 'isi terenkripsi',
          query: 'RAHASIA',
        ),
        isTrue,
      );
    });

    test('kata kunci kosong tidak membuat baris apa pun layak', () {
      expect(
        catatanLayakTampil(
          judul: 'Catatan',
          plainTersimpan: 'isi biasa',
          plainDidekripsi: 'isi biasa',
          query: '   ',
        ),
        isFalse,
      );
    });
  });
}
