import 'dart:typed_data';

import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('NoteCipher', () {
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('enkripsi lalu dekripsi mengembalikan teks asli', () {
      final cipher = NoteCipher(key);
      const text = 'isi catatan rahasia';

      expect(cipher.decrypt(cipher.encrypt(text)), text);
    });

    test('ciphertext berbeda tiap kali (nonce acak)', () {
      final cipher = NoteCipher(key);

      expect(cipher.encrypt('sama'), isNot(equals(cipher.encrypt('sama'))));
    });

    test('ciphertext tidak mengandung plaintext', () {
      final cipher = NoteCipher(key);

      expect(cipher.encrypt('rahasia-kuat'), isNot(contains('rahasia-kuat')));
    });

    test('decrypt pada teks yang tidak terenkripsi mengembalikannya apa adanya', () {
      final cipher = NoteCipher(key);

      expect(cipher.decrypt('bukan-ciphertext'), 'bukan-ciphertext');
    });

    test('decrypt pada ciphertext dengan kunci salah melempar exception', () {
      final cipher = NoteCipher(key);
      final otherKey = Uint8List.fromList(List<int>.filled(32, 3));
      final encrypted = cipher.encrypt('rahasia');

      expect(
        () => NoteCipher(otherKey).decrypt(encrypted),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('decrypt pada ciphertext rusak melempar exception', () {
      final cipher = NoteCipher(key);

      expect(
        () => cipher.decrypt('NBNOTE1.abc.def'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('isEncrypted mengenali ciphertext dan bukan plaintext', () {
      final cipher = NoteCipher(key);

      expect(cipher.isEncrypted(cipher.encrypt('x')), isTrue);
      expect(cipher.isEncrypted('plaintext biasa'), isFalse);
      expect(cipher.isEncrypted(''), isFalse);
    });
  });

  group('NoteCipher.decryptOrKeep', () {
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('ciphertext dengan kunci salah dikembalikan apa adanya', () {
      // Ini inti FIX A: dekripsi yang gagal TIDAK boleh mengubah isi menjadi
      // string kosong, karena catatan terkunci yang lalu disimpan ulang akan
      // menimpa isinya yang asli dengan string kosong (data loss).
      final cipher = NoteCipher(key);
      final otherKey = Uint8List.fromList(List<int>.filled(32, 3));
      final ciphertext = cipher.encrypt('rahasia');

      expect(NoteCipher(otherKey).decryptOrKeep(ciphertext), ciphertext);
      expect(NoteCipher(otherKey).decryptOrKeep(ciphertext), isNot(isEmpty));
    });

    test('ciphertext rusak dikembalikan apa adanya', () {
      final cipher = NoteCipher(key);

      expect(cipher.decryptOrKeep('NBNOTE1.abc.def'), 'NBNOTE1.abc.def');
    });

    test('ciphertext valid didekripsi menjadi plaintext', () {
      final cipher = NoteCipher(key);

      expect(cipher.decryptOrKeep(cipher.encrypt('rahasia')), 'rahasia');
    });

    test('teks biasa dikembalikan apa adanya', () {
      final cipher = NoteCipher(key);

      expect(cipher.decryptOrKeep('bukan-ciphertext'), 'bukan-ciphertext');
    });

    test('string kosong dikembalikan apa adanya', () {
      final cipher = NoteCipher(key);

      expect(cipher.decryptOrKeep(''), '');
    });
  });
}
