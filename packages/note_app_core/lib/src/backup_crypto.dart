/// Enkripsi payload backup (AES-256-GCM) - pure Dart, tanpa dependensi Flutter.
///
/// Format envelope (base64url, dipisah titik):
///   NBNOTE1.<nonce>.<ciphertext>.<tag>
///
/// GCM memberi dua jaminan sekaligus: kerahasiaan (AES-256) dan integritas
/// (tag otentikasi), sehingga payload yang dimodifikasi akan GAGAL didekripsi
/// alih-alih menghasilkan sampah.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Exception yang dilempar saat dekripsi gagal.
class BackupDecryptException implements Exception {
  final String message;

  const BackupDecryptException(this.message);

  @override
  String toString() => 'BackupDecryptException: $message';
}

/// Enkripsi/dekripsi payload backup dengan AES-256-GCM.
class BackupCrypto {
  /// Header envelope - dipakai untuk mengenali file backup terenkripsi.
  static const String magic = 'NBNOTE1';

  static const int _keyLength = 32; // AES-256
  static const int _nonceLength = 12; // 96 bit, recommended untuk GCM
  static const int _macSizeBits = 128; // tag 128 bit (16 byte)
  static const int _macLength = 16; // panjang tag dalam byte

  final Uint8List _key;

  BackupCrypto(List<int> key) : _key = Uint8List.fromList(key) {
    if (_key.length != _keyLength) {
      throw ArgumentError(
        'Kunci backup harus $_keyLength byte (AES-256), dapat ${_key.length}',
      );
    }
  }

  /// Enkripsi bytes -&gt; envelope string.
  String encryptBytes(List<int> plaintext) {
    final nonce = _randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_key), _macSizeBits, nonce, Uint8List(0)),
      );

    final encrypted = cipher.process(Uint8List.fromList(plaintext));
    // pointycastle GCM menaruh tag otentikasi di akhir ciphertext.
    final tagStart = encrypted.length - _macLength;
    final ciphertext = encrypted.sublist(0, tagStart);
    final tag = encrypted.sublist(tagStart);

    return [
      magic,
      base64Url.encode(nonce),
      base64Url.encode(ciphertext),
      base64Url.encode(tag),
    ].join('.');
  }

  /// Dekripsi envelope string -&gt; bytes.
  Uint8List decryptBytes(String envelope) {
    final parts = envelope.split('.');
    if (parts.length != 4 || parts[0] != magic) {
      throw const BackupDecryptException(
        'Format envelope tidak dikenali - file bukan backup terenkripsi.',
      );
    }

    final Uint8List nonce;
    final Uint8List ciphertext;
    final Uint8List tag;
    try {
      nonce = Uint8List.fromList(base64Url.decode(parts[1]));
      ciphertext = Uint8List.fromList(base64Url.decode(parts[2]));
      tag = Uint8List.fromList(base64Url.decode(parts[3]));
    } catch (_) {
      throw const BackupDecryptException('Envelope rusak - base64 tidak valid.');
    }

    if (nonce.length != _nonceLength || tag.length != _macLength) {
      throw const BackupDecryptException(
        'Panjang nonce/tag tidak sesuai - envelope rusak.',
      );
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(_key), _macSizeBits, nonce, Uint8List(0)),
      );

    try {
      final combined = Uint8List.fromList([...ciphertext, ...tag]);
      return cipher.process(combined);
    } catch (_) {
      throw const BackupDecryptException(
        'Gagal mendekripsi - kunci salah atau file sudah diubah.',
      );
    }
  }

  /// Enkripsi string UTF-8.
  String encryptString(String plaintext) =>
      encryptBytes(utf8.encode(plaintext));

  /// Dekripsi string UTF-8.
  String decryptString(String envelope) => utf8.decode(decryptBytes(envelope));

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}
