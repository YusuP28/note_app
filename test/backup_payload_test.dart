import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_app_core/note_app_core.dart';

/// Test integrasi payload backup: terenkripsi saat written, bisa dibaca
/// kembali, dan file lama (plaintext) tetap bisa dipulihkan.
void main() {
  group('Backup payload', () {
    test('payload backup terenkripsi tidak membocorkan isi catatan', () {
      final payload = {
        'version': 3,
        'notes': [
          {'id': 'n1', 'title': 'Jual Mobil', 'plain_text': 'harga 200 juta'},
        ],
      };

      final sealed = BackupEnvelope.seal(
        utf8.encode(jsonEncode(payload)),
        'passphrase-xyz',
      );

      expect(sealed, isNot(contains('Jual Mobil')));
      expect(sealed, isNot(contains('200 juta')));
      expect(sealed, startsWith(BackupEnvelope.magic));
    });

    test('payload bisa dipulihkan utuh dengan passphrase yang benar', () {
      final payload = {
        'version': 3,
        'notes': [
          {'id': 'n1', 'title': 'Jual Mobil', 'plain_text': 'harga 200 juta'},
        ],
      };

      final sealed = BackupEnvelope.seal(
        utf8.encode(jsonEncode(payload)),
        'passphrase-xyz',
      );
      final restored = jsonDecode(
        utf8.decode(BackupEnvelope.open(sealed, 'passphrase-xyz')),
      ) as Map<String, dynamic>;

      expect(restored['notes'], hasLength(1));
      final note = (restored['notes'] as List).first as Map<String, dynamic>;
      expect(note['title'], 'Jual Mobil');
      expect(note['plain_text'], 'harga 200 juta');
    });

    test('backup dari perangkat lain bisa dipulihkan dengan passphrase yang sama', () {
      // Simulasi: perangkat A membuat backup, perangkat B memulihkannya.
      final payload = {'notes': [{'id': 'n1', 'title': 'Rahasia'}]};
      final sealedDeviceA = BackupEnvelope.seal(
        utf8.encode(jsonEncode(payload)),
        'passphrase-sama',
      );

      final restoredDeviceB = jsonDecode(
        utf8.decode(BackupEnvelope.open(sealedDeviceA, 'passphrase-sama')),
      ) as Map<String, dynamic>;

      expect((restoredDeviceB['notes'] as List).first['title'], 'Rahasia');
    });

    test('passphrase berbeda tidak bisa membuka backup', () {
      final sealed = BackupEnvelope.seal(
        utf8.encode(jsonEncode({'notes': []})),
        'passphrase-a',
      );

      expect(
        () => BackupEnvelope.open(sealed, 'passphrase-b'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    test('file backup plaintext lama tetap terdeteksi (bukan terenkripsi)', () {
      expect(BackupEnvelope.isEncrypted('{"notes":[]}'), isFalse);
    });
  });
}
