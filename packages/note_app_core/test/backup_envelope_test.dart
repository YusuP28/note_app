import 'dart:convert';
import 'dart:typed_data';

import 'package:note_app_core/note_app_core.dart';
import 'package:test/test.dart';

void main() {
  group('BackupEnvelope', () {
    test('seal lalu open mengembalikan payload asli', () {
      final raw = Uint8List.fromList(utf8.encode('{"notes":[{"id":"1"}]}'));

      final envelope = BackupEnvelope.seal(raw, 'passphrase-rahasia');
      final restored = BackupEnvelope.open(envelope, 'passphrase-rahasia');

      expect(restored, raw);
    });

    test('envelope tidak mengandung plaintext', () {
      final raw = Uint8List.fromList(utf8.encode('rahasia-super'));

      final envelope = BackupEnvelope.seal(raw, 'passphrase-rahasia');

      expect(envelope, isNot(contains('rahasia-super')));
      expect(envelope, startsWith(BackupEnvelope.magic));
    });

    test('passphrase salah gagal mendekripsi', () {
      final envelope = BackupEnvelope.seal(
        Uint8List.fromList(utf8.encode('rahasia')),
        'passphrase-benar',
      );

      expect(
        () => BackupEnvelope.open(envelope, 'passphrase-salah'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('passphrase kosong ditolak', () {
      final envelope = BackupEnvelope.seal(
        Uint8List.fromList(utf8.encode('rahasia')),
        'x',
      );

      expect(
        () => BackupEnvelope.open(envelope, ''),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('envelope rusak ditolak', () {
      expect(
        () => BackupEnvelope.open('bukan-envelope', 'x'),
        throwsA(isA<BackupDecryptException>()),
      );
      expect(
        () => BackupEnvelope.open('NBNOTE2.abc', 'x'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('envelope yang dimodifikasi ditolak', () {
      final envelope = BackupEnvelope.seal(
        Uint8List.fromList(utf8.encode('rahasia')),
        'passphrase',
      );
      final parts = envelope.split('.');
      final tampered = [
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        base64Url.encode(utf8.encode('dirusak')),
      ].join('.');

      expect(
        () => BackupEnvelope.open(tampered, 'passphrase'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('salt berbeda tiap seal sehingga ciphertext berbeda', () {
      final raw = Uint8List.fromList(utf8.encode('sama'));

      final a = BackupEnvelope.seal(raw, 'p');
      final b = BackupEnvelope.seal(raw, 'p');

      expect(a, isNot(equals(b)));
    });

    test('isEncrypted mengenali format NBNOTE2 saja', () {
      expect(BackupEnvelope.isEncrypted('NBNOTE2.a.b.c.d.e'), isTrue);
      expect(BackupEnvelope.isEncrypted('  NBNOTE2.a.b.c.d.e'), isTrue);
      expect(BackupEnvelope.isEncrypted('{"notes":[]}'), isFalse);
      expect(BackupEnvelope.isEncrypted('NBNOTE1.a.b.c'), isFalse);
    });

    test('file backup lama (bukan terenkripsi) dikenali sebagai bukan terenkripsi', () {
      expect(BackupEnvelope.isEncrypted('PK\u0003\u0004...'), isFalse);
    });
  });

  group('Pbkdf2', () {
    test('derive deterministik untuk input sama', () {
      final a = Pbkdf2.derive('password', [1, 2, 3], 1000, 32);
      final b = Pbkdf2.derive('password', [1, 2, 3], 1000, 32);

      expect(a, b);
    });

    test('derive menghasilkan kunci sepanjang keyLength', () {
      expect(Pbkdf2.derive('password', [1], 1000, 32).length, 32);
      expect(Pbkdf2.derive('password', [1], 1000, 64).length, 64);
    });

    test('password berbeda menghasilkan kunci berbeda', () {
      final a = Pbkdf2.derive('password-a', [1, 2, 3], 1000, 32);
      final b = Pbkdf2.derive('password-b', [1, 2, 3], 1000, 32);

      expect(a, isNot(equals(b)));
    });

    test('salt berbeda menghasilkan kunci berbeda', () {
      final a = Pbkdf2.derive('password', [1, 2, 3], 1000, 32);
      final b = Pbkdf2.derive('password', [4, 5, 6], 1000, 32);

      expect(a, isNot(equals(b)));
    });

    test('cocok dengan test vector PBKDF2-HMAC-SHA256 standar', () {
      // P="password", S="salt", c=1, dkLen=32
      // P="password", S="salt", c=1, dkLen=32
      // = 120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b
      final key = Pbkdf2.derive('password', utf8.encode('salt'), 1, 32);

      expect(
        key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('iterations di bawah 1 ditolak', () {
      expect(
        () => Pbkdf2.derive('password', [1], 0, 32),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('keyLength tidak valid ditolak', () {
      expect(
        () => Pbkdf2.derive('password', [1], 1000, 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
