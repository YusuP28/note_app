import 'dart:convert';
import 'dart:typed_data';

import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('BackupCrypto', () {
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i));

    test('encrypt lalu decrypt mengembalikan plaintext yang sama', () {
      final crypto = BackupCrypto(key);
      const plaintext = 'rahasia: PIN 1234, catatan "jual mobil"';

      final envelope = crypto.encryptString(plaintext);
      final restored = crypto.decryptString(envelope);

      expect(restored, plaintext);
    });

    test('envelope memuat magic header dan versi', () {
      final crypto = BackupCrypto(key);
      final envelope = crypto.encryptString('halo');

      expect(envelope, startsWith(BackupCrypto.magic));
      expect(envelope.split('.').first, BackupCrypto.magic);
    });

    test('envelope tidak mengandung plaintext', () {
      final crypto = BackupCrypto(key);
      final envelope = crypto.encryptString('rahasia-kuat');

      expect(envelope, isNot(contains('rahasia-kuat')));
    });

    test('two encryptions of the same plaintext menghasilkan envelope berbeda', () {
      final crypto = BackupCrypto(key);

      final a = crypto.encryptString('sama');
      final b = crypto.encryptString('sama');

      expect(a, isNot(equals(b)));
    });

    test('decrypt dengan key yang salah gagal', () {
      final crypto = BackupCrypto(key);
      final wrongKey = Uint8List.fromList(List<int>.filled(32, 9));
      final envelope = crypto.encryptString('rahasia');

      expect(
        () => BackupCrypto(wrongKey).decryptString(envelope),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('decrypt envelope yang rusak gagal', () {
      final crypto = BackupCrypto(key);

      expect(
        () => crypto.decryptString('bukan-envelope-note-app'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('decrypt menolak payload yang dimodifikasi (tamper detection)', () {
      final crypto = BackupCrypto(key);
      final envelope = crypto.encryptString('rahasia');
      final parts = envelope.split('.');
      final tampered = [
        parts[0],
        parts[1],
        parts[2],
        base64Url.encode(utf8.encode('dirusak')),
      ].join('.');

      expect(
        () => crypto.decryptString(tampered),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('encrypt/decrypt bytes biner (bukan hanya teks)', () {
      final crypto = BackupCrypto(key);
      final bytes = Uint8List.fromList(List<int>.generate(256, (i) => i % 256));

      final envelope = crypto.encryptBytes(bytes);
      final restored = crypto.decryptBytes(envelope);

      expect(restored, bytes);
    });
  });
}
