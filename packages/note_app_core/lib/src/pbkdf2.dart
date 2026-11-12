/// Implementasi PBKDF2-HMAC-SHA256 (RFC 8018) - pure Dart.
///
/// Dipakai untuk derive kunci enkripsi backup dari passphrase, dan untuk
/// menyimpan hash PIN.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Turunan PBKDF2-HMAC-SHA256.
class Pbkdf2 {
  Pbkdf2._();

  /// Hitung kunci turunan.
  ///
  /// [iterations] minimal 1 (primitive-nya tidak memaksakan kebijakan -
  /// callers yang memutuskan batas minimum, supaya test vector standar
  /// dengan c=1 tetap bisa diverifikasi).
  static Uint8List derive(
    String password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    if (iterations < 1) {
      throw ArgumentError('iterations minimal 1, dapat $iterations');
    }
    if (keyLength <= 0) {
      throw ArgumentError('keyLength harus > 0');
    }
    final hmac = Hmac(sha256, utf8.encode(password));
    const hLen = 32;
    final blockCount = (keyLength + hLen - 1) ~/ hLen;
    final result = Uint8List(keyLength);

    for (var block = 1; block <= blockCount; block++) {
      final saltBlock = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert(saltBlock).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < hLen; j++) {
          t[j] ^= u[j];
        }
      }
      final offset = (block - 1) * hLen;
      final take = keyLength - offset < hLen ? keyLength - offset : hLen;
      for (var j = 0; j < take; j++) {
        result[offset + j] = t[j];
      }
    }
    return result;
  }
}
