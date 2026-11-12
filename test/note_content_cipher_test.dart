import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/services/backup_passphrase_service.dart';
import 'package:note_app/services/note_content_cipher.dart';

void main() {
  group('NoteContentCipher', () {
    final key = List<int>.generate(32, (i) => i + 1);

    test('konten catatan terkunci terenkripsi di database', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'id': 'n1',
        'content': '{"ops":[{"insert":"rahasia"}]}',
        'plain_text': 'rahasia',
        'is_locked': 1,
      };

      final encrypted = cipher.encryptRow(row);

      expect(encrypted['content'], isNot(contains('rahasia')));
      expect(encrypted['plain_text'], isNot(contains('rahasia')));
      expect(encrypted['content'], startsWith('NBNOTE1'));
    });

    test('konten catatan TIDAK terkunci tetap plaintext (pencarian jalan)', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'id': 'n1',
        'content': 'biasa',
        'plain_text': 'biasa',
        'is_locked': 0,
      };

      final encrypted = cipher.encryptRow(row);

      expect(encrypted['plain_text'], 'biasa');
      expect(encrypted['content'], 'biasa');
    });

    test('decryptRow mengembalikan isi asli', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'content': 'rahasia',
        'plain_text': 'rahasia',
        'is_locked': 1,
      };

      final encrypted = cipher.encryptRow(row);
      final decrypted = cipher.decryptRow(encrypted);

      expect(decrypted['content'], 'rahasia');
      expect(decrypted['plain_text'], 'rahasia');
    });

    test('catatan lama (plaintext) tetap terbaca tanpa error', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'content': 'lama',
        'plain_text': 'lama',
      };

      final decrypted = cipher.decryptRow(row);

      expect(decrypted['content'], 'lama');
    });

    test('cipher disabled tidak mengubah apa pun', () {
      final cipher = NoteContentCipher.disabled();
      final row = <String, dynamic>{'content': 'x', 'plain_text': 'y'};

      expect(cipher.isEnabled, isFalse);
      expect(cipher.encryptRow(row)['content'], 'x');
      expect(cipher.decryptRow(row)['plain_text'], 'y');
    });

    test('enkripsi dua kali tidak menggandakan (idempoten)', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'content': 'x',
        'plain_text': 'y',
        'is_locked': 1,
      };

      final once = cipher.encryptRow(row);
      final twice = cipher.encryptRow(once);

      expect(twice['content'], once['content']);
    });

    test('kolom non-string tidak bikin crash', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'content': null,
        'plain_text': null,
        'is_locked': 1,
      };

      final encrypted = cipher.encryptRow(row);

      expect(encrypted['content'], '');
    });

    test(
      'dekripsi gagal tidak menghapus isi (ciphertext asli dikembalikan)',
      () async {
        // Regression FIX A: dulu `_decryptOrKeep` mengembalikan string kosong
        // saat dekripsi gagal. Catatan terkunci yang lalu disimpan ulang
        // menimpa isinya yang asli dengan string kosong -> data loss.
        final cipher = await NoteContentCipher.fromKey(key);
        final lain = await NoteContentCipher.fromKey(
          List<int>.generate(32, (i) => 200 - i),
        );
        final row = <String, dynamic>{
          'content': 'rahasia',
          'plain_text': 'rahasia',
          'is_locked': 1,
        };
        final encrypted = lain.encryptRow(row);
        final ciphertext = encrypted['content'] as String;

        final decrypted = cipher.decryptRow(encrypted);

        expect(decrypted['content'], ciphertext);
        expect(decrypted['plain_text'], isNotEmpty);
        expect(decrypted['plain_text'], isNot(''));
      },
    );

    test(
      'catatan terkunci yang gagal didekripsi bisa disimpan ulang tanpa kehilangan isi',
      () async {
        final cipher = await NoteContentCipher.fromKey(key);
        final lain = await NoteContentCipher.fromKey(
          List<int>.generate(32, (i) => 200 - i),
        );
        final row = <String, dynamic>{
          'content': 'rahasia',
          'plain_text': 'rahasia',
          'is_locked': 1,
        };
        final encrypted = lain.encryptRow(row);

        // Siklus: baca (gagal) -> simpan ulang.
        final decrypted = cipher.decryptRow(encrypted);
        final saved = cipher.encryptRow(decrypted);

        // Isi tidak boleh berubah jadi kosong.
        expect(saved['content'], isNotEmpty);
        expect(saved['plain_text'], isNotEmpty);
        expect(saved['content'], isNot(contains('rahasia')));
      },
    );
  });

  group('NoteContentCipher.decryptText', () {
    final key = List<int>.generate(32, (i) => i + 1);

    test('teks terenkripsi dikembalikan jadi plaintext', () async {
      final cipher = await NoteContentCipher.fromKey(key);
      final row = <String, dynamic>{
        'content': '{"ops":[{"insert":"rahasia"}]}',
        'plain_text': 'rahasia',
        'is_locked': 1,
      };
      final encrypted = cipher.encryptRow(row);

      expect(
        cipher.decryptText(encrypted['content'] as String),
        '{"ops":[{"insert":"rahasia"}]}',
      );
    });

    test('teks plaintext dikembalikan apa adanya', () async {
      final cipher = await NoteContentCipher.fromKey(key);

      expect(cipher.decryptText('biasa saja'), 'biasa saja');
    });

    test('teks kosong dikembalikan apa adanya', () async {
      final cipher = await NoteContentCipher.fromKey(key);

      expect(cipher.decryptText(''), '');
    });

    test('cipher disabled tidak mengubah teks', () {
      final cipher = NoteContentCipher.disabled();

      expect(cipher.decryptText('NBNOTE1.abc.def'), 'NBNOTE1.abc.def');
    });

    test(
      'dekripsi gagal tidak menghapus isi (nilai asli dikembalikan)',
      () async {
        final cipher = await NoteContentCipher.fromKey(key);
        // Ciphertext dengan kunci yang salah -> dekripsi harus gagal, bukan
        // menghasilkan string kosong yang bisa menimpa isi catatan.
        final lain = await NoteContentCipher.fromKey(
          List<int>.generate(32, (i) => 200 - i),
        );
        final row = <String, dynamic>{
          'content': 'rahasia',
          'plain_text': 'rahasia',
          'is_locked': 1,
        };
        final encrypted = lain.encryptRow(row);
        final ciphertext = encrypted['content'] as String;

        expect(cipher.decryptText(ciphertext), ciphertext);
      },
    );
  });

  group('BackupPassphraseService', () {
    test('passphrase default minimal 8 karakter', () {
      expect(BackupPassphraseService.generatePassphrase().length,
          greaterThanOrEqualTo(8));
    });

    test('passphrase generated berbeda antar pemanggilan', () {
      final a = BackupPassphraseService.generatePassphrase();
      final b = BackupPassphraseService.generatePassphrase();

      expect(a, isNot(equals(b)));
    });
  });
}
