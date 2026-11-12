import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:note_app_core/note_app_core.dart';

/// Format file backup terenkripsi, mandiri (self-contained).
///
/// Format ASCII (base64url, dipisah titik):
///   NBNOTE2.<salt>.<iterations>.<nonce>.<ciphertext>.<tag>
///
/// Salt disimpan di header sehingga file bisa dibuka di perangkat lain -
/// asalkan passphrase-nya sama. Ini yang membuat fitur backup Google Drive
/// tetap berguna: backup bisa dipulihkan di HP baru.
class BackupEnvelope {
  static const String magic = 'NBNOTE2';
  static const int defaultIterations = 210000;
  static const int saltLength = 16;
  static const int keyLength = 32;

  /// Enkripsi payload dengan passphrase -> string envelope.
  static String seal(List<int> raw, String passphrase) {
    final salt = _randomBytes(saltLength);
    final key = Pbkdf2.derive(passphrase, salt, defaultIterations, keyLength);
    final crypto = BackupCrypto(key);
    final sealed = crypto.encryptBytes(raw);

    // BackupCrypto menghasilkan 4 bagian; gabung dengan salt + iterations.
    final parts = sealed.split('.');
    return [
      magic,
      base64Url.encode(salt),
      '$defaultIterations',
      parts[1],
      parts[2],
      parts[3],
    ].join('.');
  }

  /// Dekripsi envelope dengan passphrase -> bytes payload asli.
  static Uint8List open(String envelope, String passphrase) {
    final parts = envelope.split('.');
    if (parts.length != 6 || parts[0] != magic) {
      throw const BackupDecryptException(
        'Format backup terenkripsi tidak dikenali.',
      );
    }

    final int iterations;
    final Uint8List salt;
    try {
      salt = Uint8List.fromList(base64Url.decode(parts[1]));
      iterations = int.parse(parts[2]);
    } catch (_) {
      throw const BackupDecryptException('Header backup rusak.');
    }
    if (iterations < 1000) {
      throw const BackupDecryptException('Jumlah iterasi tidak valid.');
    }

    final key = Pbkdf2.derive(passphrase, salt, iterations, keyLength);
    final crypto = BackupCrypto(key);
    // BackupCrypto memakai magic sendiri (NBNOTE1) -olian envelope di
    // sini memakai NBNOTE2 + header salt, jadi rakit ulang bagian cipher.
    return crypto.decryptBytes(
      [BackupCrypto.magic, parts[3], parts[4], parts[5]].join('.'),
    );
  }

  /// Apakah string ini backup terenkripsi format NBNOTE2?
  static bool isEncrypted(String content) =>
      content.trimLeft().startsWith(magic);

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}
