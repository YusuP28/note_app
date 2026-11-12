import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_app_core/note_app_core.dart';

/// Menyimpan kunci enkripsi lokal (untuk konten catatan terkunci di SQLite).
///
/// Kunci 256-bit acak disimpan lewat flutter_secure_storage, yang di Android
/// memakai AES KeyStore + EncryptedSharedPreferences. Kunci tidak pernah
/// ditulis plaintext ke disk dan tidak ikut tersimpan di dalam file backup.
class LocalKeyService {
  static const _storageKey = 'local_content_key_v1';
  static const int _keyLength = 32; // AES-256

  final Future<Uint8List> Function() _keyProvider;

  LocalKeyService._(this._keyProvider);

  /// Untuk testing (inject provider kunci).
  LocalKeyService.forTesting(this._keyProvider);

  /// Default: ambil dari Keystore, buat baru bila belum ada.
  factory LocalKeyService() {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return LocalKeyService._(() async {
      final existing = await storage.read(key: _storageKey);
      if (existing != null && existing.isNotEmpty) {
        final decoded = base64Decode(existing);
        if (decoded.length == _keyLength) return Uint8List.fromList(decoded);
      }
      final created = generateKey();
      await storage.write(key: _storageKey, value: base64Encode(created));
      return created;
    });
  }

  /// Kunci aktif (dibuat bila belum ada).
  Future<Uint8List> key() => _keyProvider();

  /// Cipher untuk konten catatan.
  Future<NoteCipher> cipher() async => NoteCipher(await key());

  /// Kunci acak 256-bit.
  static Uint8List generateKey() {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_keyLength, (_) => rnd.nextInt(256)),
    );
  }
}
