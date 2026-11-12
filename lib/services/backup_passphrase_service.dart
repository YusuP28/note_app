import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:note_app_core/note_app_core.dart';

/// Menyimpan passphrase enkripsi backup file.
///
/// Berbeda dengan kunci lokal (yang device-bound), passphrase ini ikut
/// disimpan di dalam file backup sebagai hash untuk verifikasi, sehingga
/// backup bisa dipulihkan di perangkat lain selama passphrase sama -
/// ini yang membuat fitur Google Drive backup tetap berguna.
///
/// Passphrase sendiri disimpan di Android Keystore (flutter_secure_storage)
/// supaya user tidak perlu mengetiknya tiap kali backup.
class BackupPassphraseService {
  static const _passphraseKey = 'backup_passphrase_v1';
  static const _hashKey = 'backup_passphrase_hash_v1';
  static const int _saltLength = 16;
  static const int _hashIterations = 210000;

  final FlutterSecureStorage _storage;

  BackupPassphraseService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Apakah passphrase sudah pernah dibuat?
  Future<bool> hasPassphrase() async {
    final value = await _storage.read(key: _passphraseKey);
    return value != null && value.isNotEmpty;
  }

  /// Set passphrase baru (mengganti yang lama).
  Future<void> setPassphrase(String passphrase) async {
    final trimmed = passphrase.trim();
    if (trimmed.length < 8) {
      throw ArgumentError('Passphrase minimal 8 karakter.');
    }
    await _storage.write(key: _passphraseKey, value: trimmed);
    await _storage.write(
      key: _hashKey,
      value: await _hash(trimmed),
    );
  }

  /// Passphrase aktif. Null bila belum pernah dibuat.
  Future<String?> passphrase() async {
    final value = await _storage.read(key: _passphraseKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Verifikasi passphrase user terhadap hash yang tersimpan.
  Future<bool> verify(String passphrase) async {
    final stored = await _storage.read(key: _hashKey);
    if (stored == null || stored.isEmpty) return false;
    final candidate = await _hash(passphrase.trim());
    return _constantTimeEquals(candidate, stored);
  }

  /// Buat passphrase acak yang kuat (dipakai saat user meminta).
  static String generatePassphrase() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(16, (_) => alphabet[rnd.nextInt(alphabet.length)])
        .join();
  }

  Future<String> _hash(String passphrase) async {
    final salt = _randomSalt();
    final derived = Pbkdf2.derive(passphrase, salt, _hashIterations, 32);
    return jsonEncode({
      'salt': base64Encode(salt),
      'iterations': _hashIterations,
      'hash': base64Encode(derived),
    });
  }

  static List<int> _randomSalt() {
    final rnd = Random.secure();
    return List<int>.generate(_saltLength, (_) => rnd.nextInt(256));
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Pesan error yang aman ditampilkan ke user.
  static String describeError(Object error) {
    if (error is BackupDecryptException) {
      return 'Passphrase salah atau file backup rusak.';
    }
    debugPrint('BackupPassphraseService error: $error');
    return 'Gagal memproses backup: $error';
  }
}
